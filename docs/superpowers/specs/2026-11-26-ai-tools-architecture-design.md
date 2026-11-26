# AI tools (function calling) architecture: design

Date: 2026-11-26
Status: approved (2026-11-26)

## Intent

Khadeja should be able to *do* things, not only chat: Gemma calls a function
in the app, the app runs it, and Gemma answers with the result. Weather for a
named place is the first tool.

The real goal is the structure, not weather: adding the next tool (reminders,
notes, …) should mean adding one feature folder and one registration line,
without touching the chat code.

## Goals

- Each tool is its own clean-architecture feature (`data` / `domain` /
  `presentation`), plus a small `tool/` adapter.
- A shared toolbox in `core/tools` that the chat uses without knowing any
  specific tool.
- A weather tool: "What's the weather in Cairo?" → Gemma calls `get_weather`
  → real current weather → a short answer plus a weather card in the chat.
- Tool failures (no internet, unknown city) turn into a result Gemma can
  explain to the user, never a crash or a stuck "generating" state.

## Non-goals (v1)

- The user's current location (needs GPS permission and `geolocator`). The
  user names the place.
- Forecasts. Current conditions only.
- A standalone weather screen. The domain layer allows one later.
- Saving chat history with tool calls across app restarts.

## Anti-goals

- `features/chat` importing anything from `features/weather` (or any other
  tool feature).
- `weather/domain` knowing it is used as an AI tool.
- Breaking what works today: streaming, image and voice messages, clearing
  the chat, English/Arabic, RTL.

## Constraints (from the project)

- Model: Gemma 4 E2B, `.litertlm`, `ModelType.gemma4`. flutter_edge_ai uses
  its native tool path for this model. `ToolChoice.required` behaves like
  `auto` here, and Gemma 4 may write a sentence before a call (streamed as
  `TextResponse`, not kept in history).
- `tools` cannot be combined with `responseFormat` in one chat.
- `toolCallId` is null on LiteRT-LM. Results are matched by tool name.
- State management is `provider`. There is no DI setup and no HTTP client yet.
- Android already declares the `INTERNET` permission.
- The UI renders flutter_edge_ai's `Message` directly (text, images, audio).
- The system prompt says "You have no internet access and no real-time
  information". It has to change.
- Online tools are acceptable (confirmed by the user), even though the README
  promises nothing leaves the device. The README must say which tools go online.

## Approaches considered

1. **Each tool is its own feature, plus a central registry (chosen).**
   `features/<tool>/{data,domain,tool,presentation}` and
   `core/tools/{app_tool,tool_registry,tool_result}`. The chat only knows the
   `AppTool` contract. Adding a tool is one folder plus one DI line. Costs
   more files per tool, which is worth it once there are 3+ tools.
2. **One `features/tools/` feature with every tool inside it.** Fewer folders,
   but the folder grows with every tool and the tools' data layers get
   tangled together. It also goes against "each tool is a feature".
3. **Tool logic inside `ChatProvider` (a switch on `call.name`).** The fastest
   way to get weather working, but every new tool edits the chat, which is
   exactly what this design avoids.

The user picked 1, after seeing the folder tree.

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

## Design

### Folder structure

Lines marked ★ are new. Everything else exists today.

```
lib/
├── main.dart
│
├── core/
│   ├── network/
│   │   ├── error/
│   │   │   ├── app_exceptions.dart        ★ NotFoundException
│   │   │   ├── error_handler.dart         ★ ErrorHandler.handle(e).failure
│   │   │   └── failure.dart               ★ ServerFailure, NetworkFailure, NotFoundFailure
│   │   └── web_service/
│   │       ├── network_helper.dart        ★ abstract HTTP contract (get/post)
│   │       └── dio_impl.dart              ★ Dio + PrettyDioLogger, 10 s timeouts
│   ├── services/
│   │   ├── injection.dart                 ★ get_it + injectable: sl, configureInjection()
│   │   └── injection.config.dart          ★ generated by build_runner
│   ├── use_cases/
│   │   └── use_cases.dart                 ★ UseCase<ReturnType, Params> → Either<Failure, T>
│   │
│   ├── tools/                             ★ THE TOOLBOX: knows the contract, not the features
│   │   ├── app_tool.dart                  ★ abstract: name, definition (Tool), execute(args)
│   │   ├── tool_registry.dart             ★ holds all AppTools, gives definitions, dispatches calls
│   │   ├── tool_result.dart               ★ ToolSuccess / ToolFailure → Map the model can read
│   │   └── tool_result_views.dart         ★ tool name → widget builder (cards in the chat)
│   │
│   ├── localization/                      (existing)
│   └── utils/                             (existing)
│
└── features/
    │
    ├── chat/
    │   ├── data/
    │   │   ├── data_sources/
    │   │   │   ├── edge_ai_chat_datasource.dart   ★ the only file that touches flutter_edge_ai
    │   │   │   └── tool_loop.dart                 ★ runToolLoop: SDK stream → ChatEvents (testable)
    │   │   └── repositories/
    │   │       └── chat_repository_impl.dart      ★
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   ├── chat_event.dart                ★ TextChunk | ToolExecuted
    │   │   │   └── chat_entry.dart                ★ MessageEntry | ToolResultEntry
    │   │   ├── repositories/
    │   │   │   └── chat_repository.dart           ★ abstract
    │   │   └── use_cases/
    │   │       ├── init_chat.dart                 ★
    │   │       ├── send_message.dart              ★
    │   │       └── clear_chat.dart                ★
    │   └── presentation/                          (existing: screen, providers, widgets)
    │
    └── weather/                           ★ ONE TOOL = ONE FEATURE
        ├── data/
        │   ├── data_sources/
        │   │   └── weather_remote_datasource.dart  calls Open-Meteo
        │   ├── models/
        │   │   ├── geo_location_model.dart         city → lat/lon
        │   │   └── weather_model.dart              fromJson / toEntity
        │   └── repositories/
        │       └── weather_repository_impl.dart    exceptions → failures
        ├── domain/
        │   ├── entities/
        │   │   └── weather.dart                    plain Dart: city, temp, condition
        │   ├── repositories/
        │   │   └── weather_repository.dart         abstract
        │   └── use_cases/
        │       └── get_current_weather_use_case.dart
        ├── tool/
        │   └── get_weather_tool.dart       ← the adapter between the feature and the model
        └── presentation/
            └── widgets/
                └── weather_card.dart       shown inside the chat
```

### How the pieces talk

```
ChatProvider ──► SendMessage ──► ChatRepository ──► EdgeAiChatDataSource
                                                        │  openChat(tools: registry.definitions)
                                                        │  generateChatResponseWithTools(
                                                        │      onToolCall: registry.dispatch)
                                                        ▼
                                                   ToolRegistry
                                                        │ finds tool by call.name
                                                        ▼
                                                   GetWeatherTool.execute(args)
                                                        │ validates args → calls use case
                                                        ▼
                                          GetCurrentWeather ► WeatherRepository ► Open-Meteo
```

### The contract every tool implements

```dart
abstract class AppTool {
  Tool get definition;                     // name + description + JSON schema for Gemma
  String get name => definition.name;
  Future<ToolResult> execute(Map<String, dynamic> args);
}
```

### Dependency rule

```
features/chat ───► core/tools ◄─── features/weather/tool ───► features/weather/domain
                                                                ▲
                                         features/weather/data ─┘
core/services/injection.dart is the only place that imports every feature.
```

- **`chat` never imports `weather`.** It only knows `core/tools`.
- **`weather/domain` never knows it's a tool.** A weather screen could reuse it later.
- **`weather/tool` is the only bridge.** It turns the model's `args` into a use
  case call and turns the `Weather` entity into a `Map` for the model.

### The toolbox (`core/tools`)

- `AppTool`: `name`, `definition` (flutter_edge_ai `Tool`: name,
  description, JSON schema), and `Future<ToolResult> execute(Map<String, dynamic> args)`.
- `ToolResult`: sealed. `ToolSuccess(Map data)` and
  `ToolFailure(String code, String message)`. `toModelResponse()` gives the
  map sent back to Gemma, for example `{"error": "city_not_found", "message": "…"}`.
- `ToolRegistry`: built from `List<AppTool>`. `definitions` goes to
  `openChat(tools:)`. `dispatch(FunctionCallResponse)` finds the tool by name
  and runs it. It returns `ToolFailure('unknown_tool')` for an unknown name,
  and catches any exception and turns it into a `ToolFailure`. The registry
  only dispatches. Reporting results to the UI is the chat data source's job.
- `ToolResultViews`: a map from tool name to
  `Widget Function(BuildContext, Map data)`. Each feature registers its own
  builder in DI. `chat` looks it up by name and shows nothing when there is no
  builder, so chat never imports `WeatherCard`.

### Chat flow

- `EdgeAiChatDataSource` is the only file that imports flutter_edge_ai's
  engine. It owns install, `getActiveModel`, one private `_openChat()` (now
  with `tools: registry.definitions` and `supportsFunctionCalls: true`), and
  `close`. It sends with `generateChatResponseWithTools(onToolCall: registry.dispatch, maxToolTurns: 4)`.
- The data source exposes `Stream<ChatEvent>`, where `ChatEvent` is sealed:
  `TextChunk(String)` or `ToolExecuted(String toolName, ToolResult result)`.
  `send` uses a `StreamController<ChatEvent>`. Its `onToolCall` awaits
  `registry.dispatch(call)`, adds `ToolExecuted`, and returns
  `result.toModelResponse()` to the SDK. Each `TextResponse` from the SDK
  stream is added as a `TextChunk`. The controller closes when the SDK stream
  ends, and errors are forwarded.
- `ChatEntry` (sealed) is what the chat list holds: `MessageEntry(Message)`
  or `ToolResultEntry(toolName, data)`. Keeping `Message` from flutter_edge_ai
  inside `MessageEntry` is a deliberate shortcut: the existing bubbles, images
  and audio keep working unchanged.
- `ChatProvider` takes `SendMessage`, `ClearChat` and `InitChat` (resolved
  from get_it in `main.dart`). It no longer imports the engine for logic.
  `ToolExecuted` with a `ToolSuccess` adds a `ToolResultEntry` before the
  streamed reply. A `ToolFailure` adds nothing, because Gemma explains it in text.
- The existing `try/finally` keeps `isGeneratingRespond` correct when a tool
  throws or times out.

### Weather feature

- API: **Open-Meteo**, free with no API key. Two calls:
  1. Geocoding: `https://geocoding-api.open-meteo.com/v1/search?name=<city>&count=1&language=<en|ar>`
  2. Current weather: `https://api.open-meteo.com/v1/forecast?latitude=…&longitude=…&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m`
- `Weather` entity: `city`, `country`, `temperatureC`, `feelsLikeC`,
  `humidity`, `windKmh`, `condition` (an enum mapped from the WMO
  `weather_code`).
- `GetCurrentWeather(city)` → `Either<Failure, Weather>` (dartz).
- Failures: `NetworkFailure`, `NotFoundFailure`, `ServerFailure`.
  The Dio timeout is 10 s.
- `GetWeatherTool`:
  - name: `get_weather`
  - description: "Get the current weather for a city. Use when the user asks
    about weather, temperature or whether to take an umbrella."
  - schema: `{city: string, required}`, with a description of the field
  - `execute`: validates that `city` is a non-empty string, otherwise returns
    `ToolFailure('invalid_arguments')`. Calls the use case and maps
    `Weather` to `{city, country, temperature_c, feels_like_c, humidity, wind_kmh, condition}`.
- `WeatherCard`: city, a condition icon, the temperature, feels-like,
  humidity and wind. Uses `ColorScheme` (light and dark) and `AppStrings`
  for labels (English and Arabic). Directional padding for RTL.

### System prompt

Replace the "no internet access" line with: you can use the tools you are
given; for anything not covered by a tool you have no real-time information;
when a tool returns an error, tell the user briefly and simply.

### Dependencies to add

`get_it`, `dio`, `dartz`, and `mocktail` (dev). Use the latest stable
versions.

### Testing

- Unit tests: `ToolRegistry` (dispatch, unknown tool, exception → failure),
  `GetWeatherTool` (bad args, success mapping, failure mapping),
  `GetCurrentWeather`, `WeatherRepositoryImpl` (exceptions → failures),
  `WeatherModel.fromJson` with captured Open-Meteo JSON fixtures.
- Widget test: `WeatherCard` in English and Arabic (RTL).
- Manual check on a device: "What's the weather in Cairo?", the same in
  Arabic, a made-up city, airplane mode, and a normal question that must
  not call the tool.

### Adding the next tool (the checklist this design exists for)

1. Create `features/<tool>/` with `data`, `domain`, `tool/<name>_tool.dart`
   and, if it needs a card, `presentation/widgets/`.
2. In `core/services/injection.dart`, register its data source, repository, use
   case, the `AppTool`, and (optionally) its `ToolResultViews` builder.
3. Add a line to the README listing what it does and whether it goes online.

## Calls made by Claude (not discussed)

- get_it for DI, Dio for HTTP, dartz `Either` for failures.
- Open-Meteo as the weather API (no key, works for Arabic city names).
- `maxToolTurns: 4`.
- Keeping flutter_edge_ai's `Message` inside `MessageEntry` instead of a full
  domain message entity.
- Tool results are shown as a card above Gemma's reply. Failures are text only.

## Left to the builder

- Exact widget layout of `WeatherCard`, and the WMO code → icon mapping.
- File names inside the layers where this doc doesn't name them.
- Whether `InitChat` reports download progress through a stream or a callback.
