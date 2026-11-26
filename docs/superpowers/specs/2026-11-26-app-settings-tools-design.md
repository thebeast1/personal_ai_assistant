# Language, theme and time tools: design

Date: 2026-11-26
Status: approved (2026-11-26)
Builds on: `docs/superpowers/specs/2026-11-26-ai-tools-architecture-design.md`

## Intent

Let the user change the app's language and its light/dark mode by asking
Khadeja ("switch to Arabic", "dark mode please", "خلي الوضع فاتح"). This adds
two more tools to the toolbox. They're the first tools that change the app
itself instead of fetching data.

## Behaviour

- **`change_language`:** switches the whole app to English or Arabic, the
  same as the app bar button. Arabic also flips the layout to right-to-left.
- **`change_theme`:** sets light, dark, or system (follow the phone).
- Both choices are saved and survive a restart. Today only the language is
  saved, and the theme is always system.
- The change shows on screen immediately. There's no tool card: Khadeja
  confirms in her reply.
- If the requested value is already active, the tool still succeeds and says
  `"changed": false`, so Khadeja can say "It's already in dark mode."
- A value the tool doesn't know (say, "French") fails with
  `unsupported_language` / `unsupported_theme`, and Khadeja explains which
  options exist.

## Non-goals

- More languages than English and Arabic.
- A settings screen, or a theme toggle button in the app bar. Only the
  existing language button stays.
- Custom colours or themes beyond light/dark/system.

## Approaches

1. **An `app_settings` feature (chosen by the user).** Data source,
   repository, use cases and tools, like weather and location. One source of
   truth that both the tools and the app bar button go through.
2. **Tools call the providers directly.** Fewer files, but the data layer
   would depend on presentation classes, and it breaks the pattern the other
   tools follow.

## Design

```
features/app_settings/
├── data/
│   ├── data_sources/app_settings_local_data_source.dart   shared_preferences
│   └── repositories/app_settings_repository_impl.dart
├── domain/
│   ├── entities/app_settings.dart          AppSettings { language, themeMode }
│   ├── enums/app_language.dart             en, ar   (+ fromCode)
│   ├── enums/app_theme_mode.dart           light, dark, system   (+ fromName)
│   ├── repositories/app_settings_repository.dart
│   └── use_cases/
│       ├── change_language_use_case.dart   UseCase<bool, AppLanguage>   true = changed
│       └── change_theme_mode_use_case.dart UseCase<bool, AppThemeMode>
├── presentation/provider/app_settings_provider.dart
└── tool/
    ├── change_language_tool.dart
    └── change_theme_tool.dart
```

- **Data source:** reads and writes `app_language` (existing key, so a saved
  language carries over) and a new `theme_mode` key in
  `SharedPreferencesWithCache`. An unset language stays `null`, meaning
  "follow the phone", as today.
- **Repository:** `AppSettings get current`, `Stream<AppSettings> get changes`,
  `setLanguage(...)` and `setThemeMode(...)`, each returning
  `Either<Failure, bool>`. It emits on `changes` after each save.
- **`AppSettingsProvider`** replaces `LocaleProvider`. It listens to the
  repository's `changes` and exposes `Locale? locale` and `ThemeMode themeMode`
  to `MaterialApp`. `toggleLanguage(current)` goes through
  `ChangeLanguageUseCase`, so the button and the tool share one path.
  `LocaleProvider.supportedLocales` moves to `AppLanguage`.
- **DI:** `SharedPreferencesWithCache` becomes a `@preResolve` singleton in an
  `@module`, with the allowList `{app_language, theme_mode}`.
  `configureInjection()` becomes `Future<void>` and `main` awaits it.
- **Tools:**
  - `change_language`: "Change the app's language. Use when the user asks to
    switch the app to English or Arabic." Parameter
    `language: string, enum ["en", "ar"]`, required.
  - `change_theme`: "Switch the app between light mode, dark mode, or
    following the phone's setting." Parameter
    `mode: string, enum ["light", "dark", "system"]`, required.
  - Result: `{"language": "ar", "changed": true}` /
    `{"mode": "dark", "changed": false}`.
- **`ToolsInjection`:** adds both tools to `ToolRegistry`. Nothing goes in
  `ToolResultViews`.
- **System prompt:** one line: "When the user asks to change the language or
  light/dark mode, call change_language or change_theme."

## Testing

- **Data source** (mocked `SharedPreferencesWithCache`) and **repository**
  (mocked data source):
  saves and reads back both values, emits on `changes`, returns `false` when
  the value is unchanged.
- **Use cases:** pass-through with a mocked repository.
- **Tools:** valid arguments → success map; unknown or missing value →
  failure code; a repository failure → `ToolFailure`.
- **`AppSettingsProvider`:** updates `locale` / `themeMode` when the
  repository emits; `toggleLanguage` switches en ↔ ar.
- **On a device:** "switch to Arabic", "dark mode", "follow my phone's theme",
  then restart the app and check both stick.

## Third tool: `get_current_time`

Added at the user's request ("what time is it?"). The model has no clock of
its own, so without this tool it guesses or refuses.

- **Behaviour:** "What time is it?", "What's today's date?", "What day is
  it?" → Khadeja answers from the phone's clock, in the phone's time zone. No
  card; the answer is in her reply. Works offline.
- **Structure** (its own small feature, no data layer since there's nothing
  to fetch):

  ```
  features/time/
  ├── domain/
  │   ├── entities/current_time.dart            CurrentTime { DateTime local }
  │   └── use_cases/get_current_time_use_case.dart   UseCase<CurrentTime, NoParams>
  └── tool/get_current_time_tool.dart
  ```

- `GetCurrentTimeUseCase` takes a `DateTime Function() now` (defaults to
  `DateTime.now`), so tests pin the time.
- **Tool:** `get_current_time`, "Get the current local time, date and day of
  the week. Use when the user asks what time it is, today's date, or the
  day." No parameters.
- **Result:**
  `{"time": "14:05", "date": "2026-11-26", "weekday": "Thursday", "timezone": "EET", "utc_offset": "+02:00"}`.
  24-hour time and ISO date, so Gemma can phrase it in either language
  (e.g. "٢:٠٥ م").
- **Registered** in `ToolsInjection` next to the other two. System prompt line:
  "For the time, date or day of the week, call get_current_time; never guess."
- **Tests:** the use case returns the injected time; the tool formats a pinned
  time correctly, including a negative UTC offset and midnight (`00:00`).

## Calls made by Claude

- `LocaleProvider` is replaced by `AppSettingsProvider` (one provider for both
  settings) instead of keeping two providers.
- No theme button in the UI. Theme changes only go through Khadeja.
- The existing `app_language` key is kept, so nobody loses their saved
  language.
