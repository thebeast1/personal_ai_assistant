# AI Tools (Weather First) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let Gemma call app functions through a reusable toolbox, with a `get_weather` tool as the first feature.

**Architecture:** `core/tools` defines the `AppTool` contract and a `ToolRegistry`. Each tool is its own clean-architecture feature with a `tool/` adapter. The chat gets `data`/`domain` layers, and only `EdgeAiChatDataSource` talks to flutter_edge_ai, through `generateChatResponseWithTools`. The UI receives `ChatEvent`s and shows tool results as cards through `ToolResultViews`.

**Tech Stack:** Flutter, flutter_edge_ai 2.7.1 + LiteRT-LM (Gemma 4 E2B), provider, get_it, dio, dartz, mocktail (dev). Weather API: Open-Meteo.

**Spec:** `docs/superpowers/specs/2026-11-26-ai-tools-architecture-design.md`

**Naming changes from the spec:** the failures live in `core`, so the spec's `CityNotFoundFailure` is the generic `NotFoundFailure`, and `tool_result_view.dart` is `tool_result_views.dart`. The `InitChat` progress uses a callback.

## Conventions (from mismar-mobile-app)

Later tasks follow the same patterns as `mismar-mobile-app`:

- **Folders:** `data/data_sources`, `data/models`, `data/repositories`,
  `domain/params`, `domain/repositories`, `domain/use_cases`,
  `presentation/providers`. Domain entities only where a model would leak
  JSON details. Otherwise the domain returns the data model, like mismar.
- **Network:** data sources depend on `NetworkHelper`
  (`core/network/web_service/network_helper.dart`), never on Dio directly.
  `DioImpl` is the `@LazySingleton(as: NetworkHelper)`. Data sources let
  errors bubble up and throw `NotFoundException` when a request finds nothing.
- **Repositories:** `try { return Right(await dataSource.x()); } catch (e) { return Left(ErrorHandler.handle(e).failure); }`.
- **Failures:** `core/network/error/failure.dart`: `ServerFailure`,
  `NetworkFailure`, `NotFoundFailure`. Unlike mismar, `UseCase` returns
  `Either<Failure, T>` (dartz) instead of `Either<String, T>`, so tools can tell
  which failure happened.
- **Use cases:** `class GetCurrentWeatherUseCase extends UseCase<WeatherModel, GetWeatherParams>`
  annotated `@injectable`, with a `call(params)` that forwards to the repository.
- **Params:** plain classes in `domain/params` with `toJson()` (query params).
- **Models:** plain classes with a `const` constructor and `factory X.fromJson(Map<String, dynamic> json)`.
- **DI:** `get_it` + `injectable` in `core/services/injection.dart` (`sl`,
  `configureInjection()`). Annotate the classes, then run
  `dart run build_runner build --delete-conflicting-outputs`. Things injectable
  can't build (the `ToolRegistry` list, `ToolResultViews`) go in a `@module`.
- **Providers** read their use cases with `sl<XUseCase>()`, like mismar.
- **Flutter SDK:** this project needs Dart ^3.14, so use
  `~/Developer/flutter-3-50-0/bin/flutter` (the `flutter` on PATH is 3.38).

## Global Constraints

- `features/chat` must not import anything from `features/weather`. Only `core/services` imports every feature.
- `features/weather/domain` must not import `core/tools` or flutter_edge_ai.
- Only `features/chat/data/datasources/edge_ai_chat_datasource.dart` calls flutter_edge_ai's engine (`FlutterEdgeAi`, `InferenceChat`). The `Message`, `Tool`, `FunctionCallResponse` and `ModelResponse` data types may be used elsewhere.
- Chat options stay exactly as today: `supportImage: true, supportAudio: true, temperature: 1.0, topK: 64, topP: 0.95, maxOutputTokens: 1024, modelType: ModelType.gemma4, systemInstruction: AppConstants.systemInstruction`. Add `tools: registry.definitions, supportsFunctionCalls: true`.
- `maxToolTurns: 4`. Dio connect and receive timeouts: 10 s.
- Tool name: `get_weather`. Model response keys: `city, country, temperature_c, feels_like_c, humidity, wind_kmh, condition`. Failure response: `{"error": <code>, "message": <text>}`, with codes `invalid_arguments`, `city_not_found`, `no_internet`, `service_unavailable`, `unknown_tool`, `tool_error`.
- Every user-visible string goes through `AppStrings` (English + Arabic). Widgets use `ColorScheme` and directional padding.
- Existing behaviour must keep working: streaming, image and audio messages, clear chat, the language switch, RTL.
- Run tests with `flutter test <path>`. The shell prints a harmless "Unable to locate a Java Runtime" line first; ignore it.

## Review Focus

1. The model calls `get_weather` with a missing, empty, whitespace-only or non-string `city`. Expect `invalid_arguments` back to the model and no exception (Task 3).
2. Open-Meteo geocoding finds no match: the response has no `results` key at all. Expect `city_not_found` (Task 2).
3. Airplane mode or a timeout. Expect `no_internet` to reach the model, and generation still ends: the spinner stops (Tasks 2, 5).
4. The SDK stream throws partway through a reply. Expect the streamed draft kept as a message and `isGeneratingRespond == false` (Task 5).
5. An Arabic city name such as `القاهرة`. Expect geocoding called with `language=ar`, so the card shows the Arabic name (Task 2).

---

### Task 1: Core toolbox and shared infrastructure ✅ DONE (2026-11-26)

**Built:**
- Packages: `dio`, `pretty_dio_logger`, `dartz`, `get_it`, `injectable`. Dev: `build_runner`, `injectable_generator`, `mocktail`.
- `lib/core/network/web_service/network_helper.dart`: `abstract class NetworkHelper { Future<dynamic> get({required String url, Map<String, dynamic>? queryParams, CancelToken? cancelToken}); Future<dynamic> post({required String url, Map<String, dynamic>? body, Map<String, dynamic>? queryParams, CancelToken? cancelToken}); }`
- `lib/core/network/web_service/dio_impl.dart`: `@LazySingleton(as: NetworkHelper) class DioImpl`, 10 s connect/receive timeouts, `PrettyDioLogger` in debug. Returns `response.data`.
- `lib/core/network/error/failure.dart`: `abstract class Failure { String get message; }`, `ServerFailure()`, `NetworkFailure()`, `NotFoundFailure({String? error})`
- `lib/core/network/error/app_exceptions.dart`: `NotFoundException(String message)`
- `lib/core/network/error/error_handler.dart`: `ErrorHandler.handle(e).failure`. Connection errors and timeouts → `NetworkFailure`, 404 → `NotFoundFailure`, `NotFoundException` → `NotFoundFailure(error: message)`, everything else → `ServerFailure`
- `lib/core/use_cases/use_cases.dart`: `abstract class UseCase<ReturnType, Params> { Future<Either<Failure, ReturnType>> call(Params params); }` and `NoParams`
- `lib/core/services/injection.dart` (+ generated `injection.config.dart`): `sl`, `configureInjection()`, called in `main.dart`
- `lib/core/tools/`: `AppTool` (`definition`, `name`, `execute`), `ToolResult` = `ToolSuccess(data)` | `ToolFailure(code:, message:)`, `ToolRegistry(tools)` (`definitions`, `dispatch` that never throws, rejects duplicate names), `ToolResultViews(builders)`
- Tests: `test/core/network/error_handler_test.dart`, `dio_impl_test.dart`, `test/core/tools/tool_registry_test.dart`, `tool_result_test.dart`

**Later tasks use these names.** Wherever later tasks say `Dio`, `throwFromDio`,
`NoInternetException`, `ServerException` or `CityNotFound…`, read them through
the Conventions section: data sources take `NetworkHelper`, repositories use
`ErrorHandler`, and failures are `NetworkFailure` / `NotFoundFailure` /
`ServerFailure`. Tool failure codes: `NetworkFailure` → `no_internet`,
`NotFoundFailure` → `city_not_found`, `ServerFailure` → `service_unavailable`.

---

### Task 2: Weather domain and data layers

**Files:**
- Create: `lib/features/weather/domain/entities/weather.dart`
- Create: `lib/features/weather/domain/repositories/weather_repository.dart`
- Create: `lib/features/weather/domain/usecases/get_current_weather.dart`
- Create: `lib/features/weather/data/models/geo_location_model.dart`, `lib/features/weather/data/models/weather_model.dart`
- Create: `lib/features/weather/data/datasources/weather_remote_datasource.dart`
- Create: `lib/features/weather/data/repositories/weather_repository_impl.dart`
- Test: `test/features/weather/data/weather_model_test.dart`, `test/features/weather/data/weather_remote_datasource_test.dart`, `test/features/weather/data/weather_repository_impl_test.dart`, `test/features/weather/domain/get_current_weather_test.dart`
- Fixtures: `test/fixtures/open_meteo_geocoding_cairo.json`, `test/fixtures/open_meteo_geocoding_empty.json` (`{"generationtime_ms": 0.5}`, with no `results` key), `test/fixtures/open_meteo_current.json`

**Interfaces:**
- Consumes: Task 1's `UseCase`, `Failure`s, exceptions, `throwFromDio`
- Produces:
  - `enum WeatherCondition { clear, partlyCloudy, cloudy, fog, drizzle, rain, snow, thunderstorm, unknown }`
  - `class Weather { final String city; final String country; final double temperatureC; final double feelsLikeC; final int humidity; final double windKmh; final WeatherCondition condition; }` (const constructor, value equality via `==`/`hashCode`)
  - `abstract interface class WeatherRepository { Future<Either<Failure, Weather>> getCurrentWeather(String city); }`
  - `class GetCurrentWeather implements UseCase<Weather, String> { GetCurrentWeather(WeatherRepository repo); }`
  - `class GeoLocationModel { name, country, latitude, longitude; factory GeoLocationModel.fromJson(Map<String, dynamic>); }`
  - `class WeatherModel { temperatureC, feelsLikeC, humidity, windKmh, weatherCode; factory WeatherModel.fromJson(Map<String, dynamic> current); Weather toEntity(GeoLocationModel place); }`
  - `WeatherCondition weatherConditionFromWmo(int code)`
  - `abstract interface class WeatherRemoteDataSource { Future<GeoLocationModel> searchCity(String city, {required String language}); Future<WeatherModel> currentWeather({required double latitude, required double longitude}); }` and `WeatherRemoteDataSourceImpl(Dio dio)`
  - `class WeatherRepositoryImpl implements WeatherRepository { WeatherRepositoryImpl(WeatherRemoteDataSource remote); }`

Open-Meteo requests (exact):
- `GET https://geocoding-api.open-meteo.com/v1/search` with `queryParameters: {'name': city, 'count': 1, 'language': language}`
- `GET https://api.open-meteo.com/v1/forecast` with `queryParameters: {'latitude': lat, 'longitude': lon, 'current': 'temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m'}`. Parse `response.data['current']`.

WMO mapping (exact): `0` clear; `1, 2` partlyCloudy; `3` cloudy; `45, 48` fog; `51–57` drizzle; `61–67, 80–82` rain; `71–77, 85, 86` snow; `95–99` thunderstorm; anything else unknown.

- [ ] **Step 1: Capture the fixtures**

Run, and save each response as the fixture file:
`curl 'https://geocoding-api.open-meteo.com/v1/search?name=Cairo&count=1&language=en'` → `open_meteo_geocoding_cairo.json`
`curl 'https://api.open-meteo.com/v1/forecast?latitude=30.06&longitude=31.25&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m'` → `open_meteo_current.json`
Expected: valid JSON. The first has `results[0].name == "Cairo"`.

- [ ] **Step 2: Write the failing tests**

`weather_model_test.dart`:
- `GeoLocationModel.fromJson(cairoFixture['results'][0])` has `name == 'Cairo'`, `country == 'Egypt'`
- `WeatherModel.fromJson(currentFixture['current']).toEntity(place)` returns a `Weather` whose `city == 'Cairo'` and whose numbers equal the fixture values
- `weatherConditionFromWmo`: `0 → clear`, `2 → partlyCloudy`, `48 → fog`, `81 → rain`, `86 → snow`, `96 → thunderstorm`, `42 → unknown`

`weather_remote_datasource_test.dart` (mocktail `MockDio`):
- `searchCity('Cairo', language: 'en')` calls `dio.get` with the geocoding URL and `{'name': 'Cairo', 'count': 1, 'language': 'en'}`, and returns a Cairo model
- `searchCity` with the empty fixture throws `NotFoundException`
- `searchCity` when `dio.get` throws `DioException(type: connectionError)` throws `NoInternetException`
- `currentWeather(...)` calls the forecast URL with the `current` list above

`weather_repository_impl_test.dart` (mock data source):
- success returns `Right(Weather)` with `city == 'Cairo'`
- `searchCity('القاهرة', language: 'ar')` is what gets called for the Arabic input (verify `language: 'ar'`). `'Cairo'` → `language: 'en'`
- `NotFoundException` → `Left(NotFoundFailure)`, `NoInternetException` → `Left(NetworkFailure)`, `ServerException` → `Left(ServerFailure)`

`get_current_weather_test.dart`: forwards to `repo.getCurrentWeather('Cairo')` and returns its result unchanged.

- [ ] **Step 3: Run the tests to verify they fail**

Run: `flutter test test/features/weather`
Expected: FAIL, missing files

- [ ] **Step 4: Implement the files listed under Interfaces**

The repository picks the language with the existing `detectTextDirection(city) == TextDirection.rtl ? 'ar' : 'en'` from `lib/core/utils/text_direction_detector.dart`.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/features/weather`
Expected: all PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/weather test/features/weather test/fixtures
git commit -m "feat(weather): add Open-Meteo weather domain and data layers"
```

---

### Task 3: Weather tool adapter and weather card

**Files:**
- Create: `lib/features/weather/tool/get_weather_tool.dart`
- Create: `lib/features/weather/presentation/widgets/weather_card.dart`
- Modify: `lib/core/localization/app_strings.dart` (add weather strings)
- Test: `test/features/weather/tool/get_weather_tool_test.dart`, `test/features/weather/presentation/weather_card_test.dart`

**Interfaces:**
- Consumes: `AppTool`, `ToolResult` (Task 1). `GetCurrentWeather`, `Weather`, `Failure`s (Task 2)
- Produces:
  - `class GetWeatherTool extends AppTool { GetWeatherTool(GetCurrentWeather getCurrentWeather); static const toolName = 'get_weather'; }`
  - `class WeatherCard extends StatelessWidget { const WeatherCard({required Map<String, dynamic> data}); }`. Its `data` is the `ToolSuccess` map.
  - `AppStrings`: `feelsLike`, `humidity`, `wind`, `String weatherCondition(String conditionName)`

Tool definition (exact copy):
```dart
const Tool(
  name: 'get_weather',
  description: 'Get the current weather for a city. Use when the user asks '
      'about weather, temperature or whether to take an umbrella.',
  parameters: {
    'type': 'object',
    'properties': {
      'city': {
        'type': 'string',
        'description': 'City name as the user wrote it, e.g. Cairo or القاهرة',
      },
    },
    'required': ['city'],
  },
)
```

Failure mapping: `NotFoundFailure` → `city_not_found`, `NetworkFailure` → `no_internet`, `ServerFailure` → `service_unavailable`. The message is the failure's `message`.

- [ ] **Step 1: Write the failing tests**

`get_weather_tool_test.dart` (mock `GetCurrentWeather`):
- `execute({})`, `execute({'city': ''})`, `execute({'city': '   '})` and `execute({'city': 42})` each return `ToolFailure` with `code == 'invalid_arguments'` and never call the use case
- `execute({'city': ' Cairo '})` calls the use case with `'Cairo'`. On `Right(weather)` it returns `ToolSuccess` with data `{'city': 'Cairo', 'country': 'Egypt', 'temperature_c': 24.0, 'feels_like_c': 25.0, 'humidity': 40, 'wind_kmh': 12.0, 'condition': 'clear'}` (for the matching `Weather`)
- `Left(NotFoundFailure(...))` → `code == 'city_not_found'`. `Left(NetworkFailure(...))` → `no_internet`. `Left(ServerFailure(...))` → `service_unavailable`
- `definition.name == 'get_weather'` and `definition.parameters['required']` equals `['city']`

`weather_card_test.dart`:
- in an English `MaterialApp`, the card shows `Cairo`, `24°`, and the English `feelsLike` label
- with `locale: Locale('ar')` it shows the Arabic labels, and `Directionality.of` inside the card is `rtl`
- it renders in `ThemeData(brightness: Brightness.dark)` without exceptions

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/weather/tool test/features/weather/presentation`
Expected: FAIL, missing files

- [ ] **Step 3: Implement `GetWeatherTool`, `WeatherCard`, and the `AppStrings` additions**

Card layout is the builder's call: a condition icon (mapped from the `condition` name), the city and country, the temperature rounded to whole degrees with `°`, and a row with feels-like, humidity % and wind km/h. Use `colors.surfaceContainerHigh` like the assistant bubble.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/weather`
Expected: all PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/weather lib/core/localization/app_strings.dart test/features/weather
git commit -m "feat(weather): add get_weather tool and weather card"
```

---

### Task 4: Chat domain and data layers with the tool loop

**Files:**
- Create: `lib/features/chat/domain/entities/chat_event.dart`, `lib/features/chat/domain/entities/chat_entry.dart`
- Create: `lib/features/chat/domain/repositories/chat_repository.dart`
- Create: `lib/features/chat/domain/usecases/init_chat.dart`, `send_message.dart`, `clear_chat.dart`
- Create: `lib/features/chat/data/datasources/tool_loop.dart`
- Create: `lib/features/chat/data/datasources/edge_ai_chat_datasource.dart`
- Create: `lib/features/chat/data/repositories/chat_repository_impl.dart`
- Test: `test/features/chat/data/tool_loop_test.dart`

**Interfaces:**
- Consumes: `ToolRegistry`, `ToolResult` (Task 1)
- Produces:
  - `sealed class ChatEvent`, with `final class TextChunk(String text)` and `final class ToolExecuted(String toolName, ToolResult result)`
  - `sealed class ChatEntry`, with `final class MessageEntry(Message message)` and `final class ToolResultEntry(String toolName, Map<String, dynamic> data)`
  - `typedef ToolCallHandler = Future<Map<String, dynamic>> Function(FunctionCallResponse call);`
  - `Stream<ChatEvent> runToolLoop({required Stream<ModelResponse> Function(ToolCallHandler onToolCall) generate, required ToolRegistry registry})`
  - `class EdgeAiChatDataSource { EdgeAiChatDataSource(ToolRegistry registry); Future<void> init({required void Function(int percent) onProgress}); Stream<ChatEvent> send(Message message); Future<void> reset(); }`
  - `abstract interface class ChatRepository` with the same three methods, and `ChatRepositoryImpl(EdgeAiChatDataSource)` delegating to them
  - `class InitChat { Future<void> call({required void Function(int) onProgress}); }`, `class SendMessage { Stream<ChatEvent> call(Message message); }`, `class ClearChat { Future<void> call(); }`, each taking a `ChatRepository`. (These are streaming/void, so they don't implement the `Either` `UseCase` base.)

`runToolLoop` behaviour: open a `StreamController<ChatEvent>`. Call `generate(onToolCall)`, where `onToolCall` awaits `registry.dispatch(call)`, adds `ToolExecuted(call.name, result)`, and returns `result.toModelResponse()`. Each non-empty `TextResponse` becomes `TextChunk(token)`. Other response types are ignored. Forward errors with `addError`, and close the controller when the generate stream is done.

- [ ] **Step 1: Write the failing tests**

`tool_loop_test.dart` (a fake `generate` that yields scripted responses and calls `onToolCall` itself; a registry with a fake echo tool):
- text-only script `['Hi', ' there']` emits `[TextChunk('Hi'), TextChunk(' there')]`, then done
- script: text `'Checking'`, then a tool call `echo {'x': 1}`, then text `'Done'`. Emits `TextChunk('Checking')`, `ToolExecuted('echo', ToolSuccess({'x': 1}))`, `TextChunk('Done')` in that order, and the fake `generate` received `{'x': 1}` back from `onToolCall`
- an unknown tool call yields `ToolExecuted` with a `ToolFailure` whose code is `unknown_tool`, and the stream continues
- a `generate` stream that throws `StateError` after one token emits `TextChunk` and then the error, and closes
- empty `TextResponse('')` tokens are not emitted

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/chat/data/tool_loop_test.dart`
Expected: FAIL, missing files

- [ ] **Step 3: Implement the entities, `runToolLoop`, the data source, the repository and the use cases**

`EdgeAiChatDataSource` moves the install and `getActiveModel` code out of today's `ChatProvider.init()` unchanged (`maxTokens: 4096`, `supportImage`, `supportAudio`). Use one private `Future<InferenceChat> _openChat()` with the Global Constraints options, called by both `init` and `reset`. `send` does `await _chat.addQuery(message)` and then returns `runToolLoop(generate: (h) => _chat.generateChatResponseWithTools(onToolCall: h, maxToolTurns: 4), registry: _registry)`. Make `send` an `async*` that awaits `addQuery` and then `yield*`s the loop.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/chat`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/chat/domain lib/features/chat/data test/features/chat
git commit -m "feat(chat): add chat domain/data layers with tool-calling loop"
```

---

### Task 5: Wire it up: provider, chat list, DI, prompt, README

**Files:**
- Create: `lib/core/services/injection.dart`
- Modify: `lib/main.dart`
- Modify: `lib/features/chat/presentation/provider/chat_provider.dart`
- Modify: `lib/features/chat/presentation/widgets/chat_widget.dart` (list items)
- Modify: `lib/core/utils/app_constants.dart` (system prompt)
- Modify: `README.md` (Tools section, "nothing leaves the device" wording)
- Modify: `integration_test/screenshots_test.dart` only if it no longer compiles
- Delete: `test/widget_test.dart`. It's the stale Flutter counter template: it looks for a `+` button that doesn't exist and already fails today. With DI it can't even build `MyApp`.
- Test: `test/features/chat/presentation/chat_provider_test.dart`

**Interfaces:**
- Consumes: everything from Tasks 1–4
- Produces:
  - `final sl = GetIt.instance; void configureDependencies()`. Registers `Dio` (`createDio()`), `WeatherRemoteDataSource`, `WeatherRepository`, `GetCurrentWeather`, `ToolRegistry([GetWeatherTool(sl())])`, `ToolResultViews({GetWeatherTool.toolName: (context, data) => WeatherCard(data: data)})`, `EdgeAiChatDataSource`, `ChatRepository`, `InitChat`, `SendMessage`, `ClearChat`. Use lazy singletons.
  - `ChatProvider({required InitChat initChat, required SendMessage sendMessage, required ClearChat clearChat})`. `List<ChatEntry> get chatList`. `send(Message)`, `clear()`, `init()`, `draftMessage`, `installProgress`, `isInitializing`, `isGeneratingRespond` and `isClearing` keep their current names and meaning.

System prompt: replace the exact line
`- You have no internet access and no real-time information (news, weather, prices, the current date).`
with:
```
- You can use the tools you are given. For anything a tool does not cover, you have no real-time information (news, prices, the current date).
- When a tool returns an error, tell the user briefly and simply what went wrong.
```

- [ ] **Step 1: Write the failing test**

`chat_provider_test.dart` (mocktail mocks for the three use cases; `registerFallbackValue(Message(text: '', isUser: true))`):
- `send(userMsg)` with events `[TextChunk('Hi'), TextChunk('!')]` results in `chatList == [MessageEntry(userMsg), MessageEntry(<assistant 'Hi!'>)]` (compare `.message.text` and `.isUser`), with `isGeneratingRespond == false` and `draftMessage` empty
- events `[ToolExecuted('get_weather', ToolSuccess({'city': 'Cairo'})), TextChunk('Sunny')]` put a `ToolResultEntry('get_weather', {'city': 'Cairo'})` between the user message and the assistant message
- a `ToolExecuted` carrying a `ToolFailure` adds no entry
- a stream that emits `TextChunk('Par')` and then an error leaves `chatList.last` as an assistant message `'Par'` and `isGeneratingRespond == false`
- `clear()` calls `ClearChat` once and empties `chatList`. It does nothing while `isGeneratingRespond` is true.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/chat/presentation/chat_provider_test.dart`
Expected: FAIL, the constructor and `ChatEntry` types don't match

- [ ] **Step 3: Refactor `ChatProvider` onto the use cases**

Keep the `_disposed` guard and the `try/finally` → `_finishGenerationHandler()` structure. `init()` calls `initChat(onProgress: ...)`. `send` does `await for (final event in sendMessage(userMessage))`, with a `switch` on `ChatEvent`.

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/chat`
Expected: PASS

- [ ] **Step 5: Update `chat_widget.dart`, `injection.dart`, `main.dart`, the prompt and the README**

- `chat_widget.dart`: the item builder switches on `ChatEntry`. `MessageEntry` → `MessageBubble(message: e.message)`. `ToolResultEntry` → `context.read<ToolResultViews>().build(context, e.toolName, e.data)`, padded and start-aligned like assistant bubbles, or `SizedBox.shrink()` when it returns null. The empty-chat suggestion still calls `send(Message(...))`.
- `main.dart`: call `configureDependencies()` after `FlutterEdgeAi.initialize`. Wrap the app in `Provider<ToolResultViews>.value(value: sl<ToolResultViews>())`, then create `ChatProvider(initChat: sl(), sendMessage: sl(), clearChat: sl())..init()`.
- README: add a "Tools" section that lists `get_weather` (online, Open-Meteo, sends only the city name) and the 3-step "add a tool" checklist from the spec. Change any claim that no data leaves the device so it names this exception.

- [ ] **Step 6: Run everything**

Run: `flutter analyze && flutter test`
Expected: `No issues found!`, all tests PASS

Run: `grep -rn "features/weather" lib/features/chat`
Expected: no output

- [ ] **Step 7: Commit**

```bash
git add lib test README.md integration_test
git commit -m "feat: wire tool calling into chat with DI and weather card"
```

---

### Task 6: On-device verification

**Files:** none (fix anything found in the owning task's files, and commit with that task's scope)

- [ ] **Step 1: Run the app on a device or simulator** (`flutter run`) and check each case:
  - "What's the weather in Cairo?" shows a weather card, then a short English reply with the same temperature
  - "كيف الطقس في القاهرة؟" shows a card with Arabic labels and an Arabic city name, then an Arabic reply
  - "Weather in Blorptown?" shows no card; the reply says the city wasn't found
  - airplane mode, then ask for the weather: no card, the reply says there's no internet, and the spinner stops
  - "Tell me a joke" gets no tool call and no card
  - photo message, voice message, clear chat (then ask for the weather again: it still works), language switch, dark mode

Expected: all as described. Note any case where Gemma ignores the tool, and its exact wording.
