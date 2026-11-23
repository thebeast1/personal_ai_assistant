# Requirements & Implementation Plan — On-Device Gemma Chat with Web Search (RAG)

> **For Claude Code:** This is the full spec for a new Flutter app. Work **phase by phase**, in order.
> At the end of each phase, stop, summarise what was built, list anything you could not verify, and wait for confirmation before starting the next phase.
> Where this document says **"verify"**, check the current package docs / pub.dev / Hugging Face before writing code — APIs in this area change quickly.

---

## 1. Goal

Build a Flutter chat app that:

1. Runs **Gemma 4 E2B (instruction-tuned)** fully **on-device** using Google's **LiteRT-LM** runtime.
2. Can answer questions about current information by doing a **web search (Tavily API)** and feeding the results into the model's prompt (**Web Search RAG**).
3. Runs on **both Android and iOS** from a single Flutter codebase.
4. On Android, works **without Google Play Services** (target test device: **Huawei Y8p**).

Non-goals for v1: image/audio input, document RAG (PDF chat), user accounts.

---

## 2. Key facts & constraints

### Model
- Hugging Face repo: `litert-community/gemma-4-E2B-it-litert-lm` — https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm
- License: Apache-2.0.
- Model file ≈ **2.6 GB** on disk. Text-only weights can use as little as ~0.8 GB RAM.
- Context window: **32K tokens** (mobile file).
- **Verify** the exact `.litertlm` filename for mobile in the repo's "Files" tab (not the `-gpu` web file, not the Qualcomm NPU file).
- Direct download URL pattern: `https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/<filename>`

### Flutter ↔ LiteRT-LM
There is no official Google Flutter package yet. Candidate community packages (evaluate in Phase 0, pick one):

| Package | Notes |
|---|---|
| `litertlm` | Bridge to official LiteRT-LM runtimes (Android = official Gradle package via JNI; iOS = official Swift package via FFI). MIT. Supports streaming + tool calling. Unverified uploader, early versions (0.0.x). |
| `flutter_gemma` + `flutter_gemma_litertlm` | More mature ecosystem; LiteRT-LM engine is an opt-in package via FFI; lists Android and iOS support. |
| `flutter_litert_lm` | Alternative plugin; **iOS is CPU-only** and needs a local Bazel build on the Mac — least preferred for iOS. |

**The chosen package MUST support both Android and iOS**, with GPU (Metal) acceleration on iOS preferred. Verify iOS GPU support per package — some only wire up the CPU backend on iOS.

Important: LiteRT-LM needs a **real file path**, not a Flutter asset. The model must be **downloaded at runtime** to app storage — never bundled in the APK.

### Target device: Huawei Y8p
- Android 10 (EMUI 10.1), **no Google Mobile Services**.
- Kirin 710F, Mali-G51 GPU, 6 GB RAM, 128 GB storage.
- Expect **slow generation (roughly 3–7 tokens/sec on CPU)**. The GPU may not be faster than the CPU — must be measurable.

### iOS constraints
- Requires a **Mac with Xcode** to build; test on a **real iPhone** (the simulator is not representative for GPU/Metal or memory).
- **Verify** the minimum iOS version required by the chosen package and set the Podfile / deployment target accordingly.
- **Memory limits:** iOS kills apps that use too much RAM (no swap). A ~2.6 GB model is near the limit on 4 GB iPhones.
  - Add the **`com.apple.developer.kernel.increased-memory-limit`** entitlement (and consider `com.apple.developer.kernel.extended-virtual-addressing`) — verify whether the chosen package recommends these.
  - Handle memory warnings (`didReceiveMemoryWarning` / Flutter `AppLifecycleListener` + platform memory-pressure signals) by stopping generation and unloading cleanly instead of crashing.
  - Recommended minimum device: **6 GB RAM** (iPhone 12 Pro / 13 Pro / 14 / 15 and newer). Show a warning on lower-RAM devices.
- **Downloads:** iOS suspends normal downloads when the app goes to the background. Use **background URLSession** downloads (e.g. the `background_downloader` package — verify) so the 2.6 GB download continues when the user leaves the app.
- **Storage/backup:** store the model in Application Support and mark it **excluded from iCloud backup** (`NSURLIsExcludedFromBackupKey`) — Apple rejects apps that back up large re-downloadable data.
- **App Store:** downloading model weights at runtime is allowed (it's data, not executable code). Include a **Privacy Manifest** (`PrivacyInfo.xcprivacy`) and accurate App Privacy labels (search queries are sent to a third-party/our backend).
- Distribution for testing: **TestFlight**.
- Reference speed from the model page: iPhone 17 Pro GPU ≈ 56 tok/s decode. Older iPhones will be much slower.

### Hard rules
- ❌ **No dependency on Google Play Services**: no Firebase (FCM, Crashlytics, Analytics), no Google Sign-In, no Play Asset Delivery, no Play Integrity, no Android AI Core / Gemini Nano.
- ✅ `minSdkVersion` must be **≤ 29 (Android 10)** — **verify** the chosen LiteRT-LM package supports this; if not, report it before continuing.
- ✅ Every feature must work on **both Android and iOS**. Platform-specific code goes behind an interface; no feature is "done" until tested on both.
- ✅ Never ship the Tavily API key inside a release build (see Phase 5).
- ✅ Always stream model output token by token.

### Search API: Tavily
- Endpoint: `POST https://api.tavily.com/search`
- Free tier: 1,000 credits/month, no credit card. `search_depth: "basic"` = 1 credit; `"advanced"` = 2 credits → **always use `basic`**.
- Key request fields: `query`, `search_depth`, `max_results`, `include_answer`, `include_raw_content`.
- Response: `results[]` with `title`, `url`, `content` (snippet), `score`.
- **Verify** the current auth method in the docs (current docs use an `Authorization: Bearer tvly-...` header; older docs put `api_key` in the JSON body).
- Docs: https://docs.tavily.com/documentation/api-reference/endpoint/search

---

## 3. Architecture

Feature-first clean architecture. State management: **Riverpod** (unless there's a strong reason otherwise — explain if you change it).

```
lib/
  main.dart
  app/                     # app widget, theme, routing
  core/
    config/                # env/config (dart-define), constants
    errors/                # failure types
    utils/                 # token estimation, text trimming
  features/
    model_manager/         # download, verify, delete, load model
      data/  domain/  presentation/
    llm/                   # LlmEngine abstraction + LiteRT-LM implementation
      data/  domain/
    search/                # SearchRepository abstraction + Tavily / backend impls
      data/  domain/
    rag/                   # prompt builder, search-decision logic, orchestration
      domain/
    chat/                  # chat UI, messages, sources display
      data/  domain/  presentation/
    settings/              # backend choice (CPU/GPU), search on/off, answer length
```

### Key abstractions (so implementations can be swapped)

```dart
abstract class LlmEngine {
  Future<void> load({required String modelPath, required LlmBackend backend});
  Stream<String> generate(String prompt, {int? maxTokens});   // streaming tokens
  Future<void> cancel();
  Future<void> dispose();
  bool get isLoaded;
}

enum LlmBackend { cpu, gpu }   // gpu = OpenCL/OpenGL on Android, Metal on iOS (as supported)

abstract class SearchRepository {
  Future<List<SearchResult>> search(String query, {int maxResults = 5});
}

class SearchResult { final String title; final String url; final String snippet; }
```

- `TavilySearchRepository` — calls Tavily directly (dev builds only).
- `BackendSearchRepository` — calls our own backend proxy (Phase 5, release builds).

---

## 4. Phases

### Phase 0 — Project setup & package spike
- Create the Flutter project targeting **Android and iOS** (bundle ID / application ID set, app name, icons placeholder).
- Set up lints (`flutter_lints` or `very_good_analysis`), Riverpod, `dio`, `path_provider`.
- **Spike:** evaluate the LiteRT-LM packages in §2. For the chosen one, confirm:
  - Android minSdk ≤ 29
  - iOS support, minimum iOS version, and whether **Metal GPU** is available on iOS
  - any extra iOS build steps (CocoaPods / Swift Package Manager / Bazel) — prefer packages with no local native build step
  - streaming support
  - CPU and GPU backend selection on both platforms
  - no Google Play Services dependency (inspect its Gradle dependencies)
- Write a short `docs/decisions.md` with the chosen package, per-platform support table, and why.

**Done when:** project builds an empty **APK and iOS app** (runs on a real iPhone), and `docs/decisions.md` exists with the choice and any risks.

---

### Phase 1 — Model download & management
- On first launch, show a **Model Setup** screen:
  - Explain the download size (~2.6 GB), recommend Wi-Fi.
  - Check free storage before starting; show an error if not enough (need size + ~500 MB margin).
- Download with `dio` to the app's documents/support directory:
  - Progress bar (MB downloaded / total, %).
  - **Resumable** downloads (HTTP Range) — mobile connections drop.
  - Cancel button.
  - Download to a temp file, then rename when complete.
- Verify the file (size check; checksum if the repo provides one).
- Settings screen: show model status, size on disk, "Delete model" button.
- **iOS specifics:**
  - Use a background-capable downloader so the download continues when the app is backgrounded; show a local notification when complete (ask for notification permission only at that moment).
  - Save to Application Support and set **exclude-from-backup** on the file.
- **Android specifics:** download continues while the app is in the foreground at minimum; a foreground service/WorkManager-based background download is a nice-to-have (must not depend on Google services).

**Done when:** the model downloads on **both platforms**, survives an interrupted connection (resume works), continues in the background on iOS, and the path is saved/persisted.

---

### Phase 2 — Basic on-device chat (no search)
- Implement `LiteRtLmEngine implements LlmEngine` using the chosen package.
- Load the model in the background with a loading indicator (first load can be slow on the Y8p).
- Chat screen:
  - Message list (user / assistant bubbles), text input, send button.
  - **Streaming** assistant replies, token by token.
  - **Stop generating** button.
  - Markdown rendering for replies (e.g. `flutter_markdown` or a maintained alternative — verify).
- System prompt (default):
  > You are a helpful assistant running on the user's phone. Answer clearly and briefly (2–5 sentences) unless the user asks for more detail.
- Settings: backend toggle **CPU / GPU** (default **CPU**), and "Answer length: short / normal".
- Chat history in the prompt: keep only the **last 4 turns** (configurable).
- Show a simple **tokens/sec** readout in debug builds (for measuring on the Y8p).
- Handle errors: model failed to load, out of memory, `LiteRtLmException` (or equivalent) → friendly message + "retry on CPU" option.
- **iOS:** add the increased-memory-limit entitlement if needed; respond to memory warnings by stopping generation and unloading the engine gracefully; reload on next use.
- Device check on startup: if device RAM is below the recommended minimum (iOS < 6 GB, Android < 4 GB), show a one-time warning that answers may be slow or the model may fail to load.

**Done when:** I can chat with Gemma fully offline (airplane mode) on a **real Android device and a real iPhone**, with streaming and stop working.

---

### Phase 3 — Tavily search client
- Implement `TavilySearchRepository`.
- API key from `--dart-define=TAVILY_API_KEY=...` (never committed; add example to README).
- Request defaults: `search_depth: "basic"`, `max_results: 5`, `include_answer: false`, `include_raw_content: false`.
- Timeouts (e.g. 10 s), error handling (no internet, 401 bad key, 429 rate limit / out of credits).
- Map results to `SearchResult`; trim each snippet to ~500 characters.
- Unit tests with a mocked HTTP client.

**Done when:** a debug screen or test can run a query and print titles/snippets/URLs.

---

### Phase 4 — Web Search RAG
Connect search + model.

**Flow:**
```
user question
  → decide: needs search?
      no  → normal chat prompt
      yes → Tavily search → build RAG prompt → Gemma (streaming)
  → show answer + source links
```

**Search decision (v1, simple & cheap):**
- A toggle in the chat input: 🔍 **Web search on/off** (default on).
- When on, skip search for obvious small talk (greetings, thanks, very short messages) using a simple rule-based check.
- (Phase 6 can replace this with model-driven tool calling.)

**RAG prompt template:**
```
You are a helpful assistant. Answer the question using ONLY the search results below.
If the results do not contain the answer, say you could not find it.
Cite sources as [1], [2], etc. Keep the answer short (2–5 sentences).

Search results:
[1] {title} — {snippet} ({url})
[2] ...

Question: {question}
Answer:
```

**Context budget (important for the Y8p — keep prompts small = faster):**
- Max **3–5** results, each snippet ≤ ~500 chars.
- Target total prompt **≤ ~3,000 tokens**. Add a rough token estimator (≈ chars / 4 for English; Arabic uses more tokens — be conservative) and drop history/results if over budget.

**UI:**
- While searching: show a "Searching the web…" state, then "Reading results…", then stream the answer.
- Under the answer: tappable **source chips/cards** (title + domain) that open the URL with `url_launcher`.
- If search fails (offline, no credits): fall back to answering without search and show a small notice ("Web search unavailable — answering from the model's own knowledge, which may be out of date").

**Done when:** asking a current-events question returns a short answer with [n] citations and working source links; offline still works without search.

---

### Phase 5 — Secure the API key (backend proxy)
The Tavily key must not live in the release APK (it can be extracted).

- Add `BackendSearchRepository` that calls our own endpoint, e.g. `GET {BACKEND_URL}/search?q=...` → returns `[{title, url, snippet}]`.
- Select implementation via build config: dev → Tavily direct; release → backend.
- Backend itself is a **separate project** (NestJS + TypeScript) — out of scope for this repo, but document the expected API contract in `docs/backend_contract.md`:
  - `GET /search?q=<query>&max=<n>` → `200 { results: [{ title, url, snippet }] }`
  - Errors: `429` rate limited, `502` upstream failure.
  - Backend responsibilities: hold the Tavily key, per-device rate limiting, cache repeated queries.

**Done when:** release builds on **both platforms** contain no Tavily key and search via the backend URL.

### Phase 5b — iOS release readiness
- `PrivacyInfo.xcprivacy` privacy manifest (declare required-reason APIs used by dependencies, e.g. file timestamps, UserDefaults).
- App Privacy answers documented in `docs/app_store_privacy.md` (search queries leave the device; chat stays on device).
- Info.plist usage strings for anything requested (e.g. notifications).
- Verify the model file is excluded from iCloud backup.
- Archive and upload a **TestFlight** build.

**Done when:** a TestFlight build installs and passes the iOS manual checklist in §6.

---

### Phase 6 — Optional improvements (only after 0–5 are done)
- Model-decided search via **tool/function calling** (`search_web(query)` tool) if the chosen package supports it reliably with Gemma 4 E2B.
- Let the model rewrite the user's question into a better search query before calling Tavily.
- Persist chat history locally (e.g. `drift` or `isar`/`objectbox` — verify maintenance status).
- Arabic UI + RTL support.
- Low-end device fallback: if measured speed < N tok/s, suggest shorter answers or a cloud model.

---

## 5. Non-functional requirements

| Area | Requirement |
|---|---|
| Performance | Stream tokens immediately; prompts ≤ ~3K tokens; model loaded once and reused. |
| Memory | Dispose engine/conversation properly; release on app background if memory pressure is reported; never crash on iOS memory warnings. |
| Offline | Chat works fully offline; only search needs the network. |
| Privacy | Chat content stays on device; only the search query is sent out (state this in the app's About screen). |
| Platforms | Android (API 29+) and iOS (min version per chosen package) from one codebase. |
| No GMS | Android app must install and run on Huawei Y8p (no Google services). |
| Errors | Every failure path (download, load, generation, search) shows a clear message and a recovery action. |
| Code quality | Null-safe, lint-clean, abstractions above, unit tests for prompt builder, token budget trimming, search client, and search-decision logic. |

---

## 6. Testing checklist

- [ ] Unit: RAG prompt builder output, token-budget trimming, Tavily response parsing, small-talk detector.
- [ ] Widget: chat screen streaming, stop button, source chips.
- [ ] Manual on **Huawei Y8p**: install APK (no Play Store), download model, chat offline, CPU vs GPU tokens/sec, RAG question, kill app mid-download → resume.
- [ ] Manual on a modern Android phone: compare speed.
- [ ] Manual on a **real iPhone** (ideally one 6 GB RAM model + one newer model): download model, background the app mid-download (continues), chat offline, CPU vs GPU (Metal) tokens/sec, RAG question, open source links.
- [ ] iOS memory: long chat + RAG prompt does not crash; memory warning is handled gracefully.
- [ ] iOS backup: model file shows as excluded from iCloud backup.
- [ ] Airplane mode (both platforms): app still chats; search shows the fallback notice.

---

## 7. Deliverables

- Flutter app source (Android + iOS).
- `README.md`: setup, how to pass `TAVILY_API_KEY` via `--dart-define`, how to build the APK and the iOS app (Xcode/signing steps), known limitations per platform.
- `docs/decisions.md`: package choice, per-platform support, CPU/GPU speed results from the Y8p and the test iPhone.
- `docs/app_store_privacy.md`: iOS privacy answers.
- `docs/backend_contract.md`: search proxy API contract.

---

## 8. References
- Model: https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm
- LiteRT-LM (Google AI Edge): https://github.com/google-ai-edge/LiteRT-LM
- `litertlm` package: https://pub.dev/packages/litertlm
- `flutter_gemma`: https://pub.dev/packages/flutter_gemma
- Tavily search API: https://docs.tavily.com/documentation/api-reference/endpoint/search
- Tavily credits/pricing: https://docs.tavily.com/documentation/api-credits
