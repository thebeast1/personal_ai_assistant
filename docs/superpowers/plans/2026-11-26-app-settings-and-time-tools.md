# Language, Theme and Time Tools Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add three Gemma tools: `get_current_time`, `change_language` (en/ar) and `change_theme` (light/dark/system), with the language and theme saved across launches.

**Architecture:** `features/time` is a domain use case plus a tool. `features/app_settings` follows the weather/location layout: a shared_preferences data source, a repository that emits changes, use cases, a presentation `AppSettingsProvider` that replaces `LocaleProvider`, and two tools. All three tools are registered in `ToolsInjection`.

**Tech Stack:** Flutter (use `~/Developer/flutter-3-50-0/bin/flutter`), flutter_edge_ai `Tool`, dartz `Either`, get_it + injectable, shared_preferences `SharedPreferencesWithCache`, provider, mocktail.

**Spec:** `docs/superpowers/specs/2026-11-26-app-settings-tools-design.md`

## Global Constraints

- Flutter binary: `~/Developer/flutter-3-50-0/bin/flutter`; codegen: `~/Developer/flutter-3-50-0/bin/dart run build_runner build --delete-conflicting-outputs`.
- Saved keys: `app_language` (existing, unchanged) and `theme_mode` (new).
- Tool names exactly: `get_current_time`, `change_language`, `change_theme`.
- Failure messages are English (Gemma rephrases them).
- None of the three tools gets an entry in `ToolResultViews`.
- Every use case extends `UseCase<T, P>` and returns `Either<Failure, T>`; classes are `@injectable` / `@LazySingleton(as: ...)` like the existing features.
- Commit at the end of each task, message ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. Gemma sends `"Arabic"`, `"arabic"` or `"AR"` instead of `"ar"` (or `"Dark"` for the theme): accept codes and English names case-insensitively. Tests in Task 4.
2. First launch with nothing saved: the language follows the phone (`null`) and the theme is `system`. Test in Task 2.
3. A saved value the app no longer understands (`'fr'`, `'blue'`): treated as unset, no crash. Test in Task 2.
4. Saving throws: the setting doesn't change in memory, nothing is emitted, and the tool returns a failure. Tests in Tasks 2 and 4.
5. Switching the language while Khadeja is replying must not reset the chat (the `ChatProvider` under `home` must survive the `MaterialApp` rebuild). Checked on device in Task 3; `home` keeps the same widget type and position, so Flutter keeps its state.

---

### Task 1: `get_current_time` tool

**Files:**
- Create: `lib/features/time/domain/entities/current_time.dart`
- Create: `lib/features/time/domain/use_cases/get_current_time_use_case.dart`
- Create: `lib/features/time/tool/get_current_time_tool.dart`
- Modify: `lib/core/services/injection.dart` (ToolsInjection), `lib/core/utils/app_constants.dart` (system prompt)
- Test: `test/features/time/domain/get_current_time_use_case_test.dart`, `test/features/time/tool/get_current_time_tool_test.dart`

**Interfaces:**
- Produces: `class CurrentTime { const CurrentTime({required DateTime local, required String timeZoneName, required Duration utcOffset}); }`
- Produces: `@injectable class GetCurrentTimeUseCase extends UseCase<CurrentTime, NoParams>`, constructor `GetCurrentTimeUseCase({@ignoreParam DateTime Function()? now})` defaulting to `DateTime.now`. (Ruling allowed: if injectable rejects the function param, use a factory constructor in the module instead.)
- Produces: `@injectable class GetCurrentTimeTool extends AppTool` with `static const toolName = 'get_current_time'`, constructor `GetCurrentTimeTool({required GetCurrentTimeUseCase getCurrentTimeUseCase})`.

- [ ] **Step 1: Write the failing tests**

Use case: `'returns the injected time with its zone and offset'` builds the use case with `now: () => DateTime(2026, 11, 26, 14, 5)` and expects `local` equal to that value, `timeZoneName == value.timeZoneName`, `utcOffset == value.timeZoneOffset`.

Tool (mock the use case with mocktail, `registerFallbackValue(const NoParams())`):
- `'the definition takes no arguments'`: `tool.name == 'get_current_time'`, `definition.parameters['required']` is empty.
- `'formats an afternoon time'`: `CurrentTime(local: DateTime(2026, 11, 26, 14, 5), timeZoneName: 'EET', utcOffset: Duration(hours: 2))` → data equals `{'time': '14:05', 'date': '2026-11-26', 'weekday': 'Thursday', 'timezone': 'EET', 'utc_offset': '+02:00'}`.
- `'formats midnight and a negative half-hour offset'`: `DateTime(2027, 1, 3, 0, 7)`, `'NST'`, `Duration(hours: -3, minutes: -30)` → `time '00:07'`, `date '2027-01-03'`, `weekday 'Sunday'`, `utc_offset '-03:30'`.
- `'a failure becomes time_unavailable'`: use case returns `Left(ServerFailure())` → `ToolFailure.code == 'time_unavailable'`.

- [ ] **Step 2: Run them and watch them fail**

Run: `~/Developer/flutter-3-50-0/bin/flutter test test/features/time`
Expected: FAIL, compile errors (files don't exist).

- [ ] **Step 3: Implement the entity, use case and tool**

Tool description (exact): `'Get the current local time, date and day of the week. Use when the user asks what time it is, today\'s date, or what day it is.'`, parameters `{'type': 'object', 'properties': {}, 'required': []}`. Format with zero-padded `padLeft(2, '0')` (no `intl`); weekday from a `const` English list indexed by `DateTime.weekday - 1`.

- [ ] **Step 4: Register the tool and update the prompt**

Add `GetCurrentTimeTool getCurrentTimeTool` to `ToolsInjection.toolRegistry` and to the list. In `AppConstants`, change the line `For anything a tool does not cover, you have no real-time information (news, prices, the current date).` to `For anything a tool does not cover, you have no real-time information (news, prices).` and add `- For the time, date or day of the week, call get_current_time. Never guess them.` Run codegen.

- [ ] **Step 5: Run the tests**

Run: `~/Developer/flutter-3-50-0/bin/flutter test && ~/Developer/flutter-3-50-0/bin/flutter analyze`
Expected: all pass, `No issues found!`

- [ ] **Step 6: Commit** — `feat(time): add get_current_time tool`

---

### Task 2: app_settings domain and data

**Files:**
- Create: `lib/features/app_settings/domain/enums/app_language.dart`, `domain/enums/app_theme_mode.dart`, `domain/entities/app_settings.dart`, `domain/repositories/app_settings_repository.dart`, `domain/use_cases/change_language_use_case.dart`, `domain/use_cases/change_theme_mode_use_case.dart`
- Create: `lib/features/app_settings/data/data_sources/app_settings_local_data_source.dart`, `data/repositories/app_settings_repository_impl.dart`
- Create: `lib/core/services/storage_injection.dart` (or a `@module` in `injection.dart`)
- Modify: `lib/core/network/error/failure.dart` (add `CacheFailure`), `lib/core/services/injection.dart` (`configureInjection` becomes `Future<void>`), `lib/main.dart` (`await configureInjection();`)
- Test: `test/features/app_settings/data/app_settings_local_data_source_test.dart`, `test/features/app_settings/data/app_settings_repository_impl_test.dart`, `test/features/app_settings/domain/change_settings_use_cases_test.dart`

**Interfaces:**
- Produces: `enum AppLanguage { en, ar }` with `String get code` and `static AppLanguage? parse(String? value)`: case-insensitive, accepts `en`/`english`/`ar`/`arabic`, else `null`.
- Produces: `enum AppThemeMode { light, dark, system }` with `static AppThemeMode? parse(String? value)`: case-insensitive name, else `null`.
- Produces: `class AppSettings { const AppSettings({this.language, this.themeMode = AppThemeMode.system}); final AppLanguage? language; final AppThemeMode themeMode; AppSettings copyWith(...); }` with `==`/`hashCode`.
- Produces: `class CacheFailure extends Failure`, message `'Could not save the setting.'`
- Produces: `abstract class AppSettingsLocalDataSource { AppSettings read(); Future<void> saveLanguage(AppLanguage); Future<void> saveThemeMode(AppThemeMode); }`, impl `@LazySingleton(as: AppSettingsLocalDataSource)` taking `SharedPreferencesWithCache`, with `static const languageKey = 'app_language'`, `themeModeKey = 'theme_mode'`.
- Produces: `abstract class AppSettingsRepository { AppSettings get current; Stream<AppSettings> get changes; Future<Either<Failure, bool>> setLanguage(AppLanguage); Future<Either<Failure, bool>> setThemeMode(AppThemeMode); }`. Impl is `@LazySingleton(as: AppSettingsRepository)`, reads `current` once in its constructor, uses a broadcast `StreamController`.
- Produces: `ChangeLanguageUseCase extends UseCase<bool, AppLanguage>`, `ChangeThemeModeUseCase extends UseCase<bool, AppThemeMode>` (pass-through to the repository; `true` = changed).
- Produces: a `@module` with `@preResolve @singleton Future<SharedPreferencesWithCache> prefs()` using allowList `{AppSettingsLocalDataSourceImpl.languageKey, AppSettingsLocalDataSourceImpl.themeModeKey}`.

- [ ] **Step 1: Write the failing tests**

Data source (mock `SharedPreferencesWithCache` with mocktail):
- `'nothing saved gives no language and the system theme'` → `read() == AppSettings()`.
- `'reads saved values'`: `getString('app_language') → 'ar'`, `getString('theme_mode') → 'dark'` → `AppSettings(language: AppLanguage.ar, themeMode: AppThemeMode.dark)`.
- `'unknown saved values are treated as unset'`: `'fr'` / `'blue'` → `AppSettings()`.
- `'saves the language code and the theme name'`: verify `setString('app_language', 'ar')` and `setString('theme_mode', 'light')`.

Repository (mock the data source):
- `'current comes from the data source'`.
- `'setLanguage saves, updates current and emits'`: expect `Right(true)`, `current.language == AppLanguage.ar`, and `changes` emits `AppSettings(language: AppLanguage.ar)` (use `expectLater(repo.changes, emits(...))` before the call).
- `'setting the same value returns false and does not save'`: `verifyNever(() => dataSource.saveThemeMode(any()))`.
- `'a save error returns CacheFailure and keeps current'`: `saveThemeMode` throws → `Left(isA<CacheFailure>())`, `current` unchanged, nothing emitted (subscribe to `changes` before the call, collect into a list, and expect it empty afterwards).

Use cases: each forwards its argument and returns the repository's result.

- [ ] **Step 2: Run them and watch them fail**

Run: `~/Developer/flutter-3-50-0/bin/flutter test test/features/app_settings`
Expected: FAIL, compile errors.

- [ ] **Step 3: Implement enums, entity, failure, data source, repository, use cases, the prefs module; make `configureInjection` async and await it in `main`; run codegen**

`main.dart` keeps creating its own prefs for `LocaleProvider` until Task 3.

- [ ] **Step 4: Run the tests**

Run: `~/Developer/flutter-3-50-0/bin/flutter test && ~/Developer/flutter-3-50-0/bin/flutter analyze`
Expected: all pass, `No issues found!`

- [ ] **Step 5: Commit** — `feat(app-settings): add settings repository and use cases`

---

### Task 3: AppSettingsProvider replaces LocaleProvider

**Files:**
- Create: `lib/features/app_settings/presentation/provider/app_settings_provider.dart`
- Delete: `lib/core/localization/locale_provider.dart`
- Modify: `lib/main.dart`, `lib/features/chat/presentation/chat_screen.dart:52`
- Test: `test/features/app_settings/presentation/app_settings_provider_test.dart`

**Interfaces:**
- Consumes: `AppSettingsRepository`, `ChangeLanguageUseCase` from Task 2.
- Produces: `class AppSettingsProvider extends ChangeNotifier` with constructor `AppSettingsProvider({AppSettingsRepository? repository, ChangeLanguageUseCase? changeLanguageUseCase})` defaulting to `sl` (like `ChatProvider`); `Locale? get locale`; `ThemeMode get themeMode`; `static final List<Locale> supportedLocales` (from `AppLanguage.values`); `Future<void> toggleLanguage(Locale current)`; listens to `repository.changes` and cancels the subscription in `dispose`.

- [ ] **Step 1: Write the failing tests** (mock repository with a `StreamController<AppSettings>.broadcast()` behind `changes`)

- `'starts from the saved settings'`: current `AppSettings(language: AppLanguage.ar, themeMode: AppThemeMode.dark)` → `locale == Locale('ar')`, `themeMode == ThemeMode.dark`.
- `'no saved language gives a null locale'`.
- `'updates and notifies when the repository emits'`: emit `AppSettings(themeMode: AppThemeMode.light)`, `await pumpEventQueue()`, `themeMode == ThemeMode.light` and the listener was called once.
- `'toggleLanguage switches en to ar and ar to en'`: verify the use case is called with `AppLanguage.ar` for `Locale('en')` and `AppLanguage.en` for `Locale('ar')`.

- [ ] **Step 2: Run them and watch them fail**

Run: `~/Developer/flutter-3-50-0/bin/flutter test test/features/app_settings/presentation`
Expected: FAIL, compile errors.

- [ ] **Step 3: Implement the provider; wire it in**

`main.dart`: drop the local prefs and `LocaleProvider`, use `ChangeNotifierProvider(create: (_) => AppSettingsProvider())`, `locale: settings.locale`, `supportedLocales: AppSettingsProvider.supportedLocales`, `themeMode: settings.themeMode` (where `settings = context.watch<AppSettingsProvider>()`), update the theme comment. `chat_screen.dart`: `context.read<AppSettingsProvider>().toggleLanguage(Localizations.localeOf(context))`. Delete `locale_provider.dart`.

- [ ] **Step 4: Run the tests**

Run: `~/Developer/flutter-3-50-0/bin/flutter test && ~/Developer/flutter-3-50-0/bin/flutter analyze`
Expected: all pass, `No issues found!`, and `grep -rn LocaleProvider lib test` prints nothing.

- [ ] **Step 5: Commit** — `refactor(app-settings): replace LocaleProvider with AppSettingsProvider`

---

### Task 4: `change_language` and `change_theme` tools

**Files:**
- Create: `lib/features/app_settings/tool/change_language_tool.dart`, `lib/features/app_settings/tool/change_theme_tool.dart`
- Modify: `lib/core/services/injection.dart`, `lib/core/utils/app_constants.dart`, `README.md`, spec status line
- Test: `test/features/app_settings/tool/change_language_tool_test.dart`, `test/features/app_settings/tool/change_theme_tool_test.dart`

**Interfaces:**
- Consumes: `ChangeLanguageUseCase`, `ChangeThemeModeUseCase`, `AppLanguage.parse`, `AppThemeMode.parse` from Task 2.
- Produces: `@injectable ChangeLanguageTool` (`toolName = 'change_language'`, ctor `{required ChangeLanguageUseCase changeLanguageUseCase}`), `@injectable ChangeThemeTool` (`toolName = 'change_theme'`, ctor `{required ChangeThemeModeUseCase changeThemeModeUseCase}`).

- [ ] **Step 1: Write the failing tests** (mock the use cases; `registerFallbackValue(AppLanguage.en)` / `AppThemeMode.system`)

Language tool:
- `'the definition requires language with en and ar'`: `parameters['required'] == ['language']`, `parameters['properties']['language']['enum'] == ['en', 'ar']`.
- `'switching returns the language and changed'`: `{'language': 'ar'}`, use case `Right(true)` → data `{'language': 'ar', 'changed': true}`.
- `'already active returns changed false'`: `Right(false)` → `'changed': false`.
- `'accepts names and any case'`: `'Arabic'` and `'EN'` call the use case with `AppLanguage.ar` / `AppLanguage.en`.
- `'unknown or missing language fails'`: `{'language': 'fr'}` and `{}` → code `unsupported_language`, message mentions `en` and `ar`, use case never called.
- `'a save failure fails'`: `Left(CacheFailure())` → code `settings_not_saved`, message `'Could not save the setting.'`.

Theme tool: same six cases with `mode`, enum `['light', 'dark', 'system']`, result `{'mode': 'dark', 'changed': true}`, `'Dark'` accepted, `'blue'` → `unsupported_theme`, failure → `settings_not_saved`.

- [ ] **Step 2: Run them and watch them fail**

Run: `~/Developer/flutter-3-50-0/bin/flutter test test/features/app_settings/tool`
Expected: FAIL, compile errors.

- [ ] **Step 3: Implement the tools**

Descriptions (exact): `change_language`: `"Change the app's language. Use when the user asks to switch the app to English or Arabic."`; `change_theme`: `"Switch the app between light mode, dark mode, or following the phone's setting (system)."` Unsupported messages: `'Only English (en) and Arabic (ar) are supported.'` / `'Only light, dark and system are supported.'`

- [ ] **Step 4: Register, prompt, docs**

Add both to `ToolsInjection.toolRegistry` (list order: weather, local weather, time, language, theme). Add to the prompt: `- When the user asks to change the app's language or light/dark mode, call change_language or change_theme, then confirm in one short sentence.` Run codegen. README: add the three tools to the tools list and structure tree. Spec status → `approved, built (2026-11-26)`.

- [ ] **Step 5: Run the tests**

Run: `~/Developer/flutter-3-50-0/bin/flutter test && ~/Developer/flutter-3-50-0/bin/flutter analyze`
Expected: all pass, `No issues found!`

- [ ] **Step 6: Commit** — `feat(app-settings): add change_language and change_theme tools`

---

## On-device check (after Task 4, by the user)

"What time is it?", "What's the date?", "Switch to Arabic", "Dark mode", "Follow my phone's theme", "Switch to French" (Khadeja says only en/ar), switch the language mid-reply (chat stays), restart (language and theme stick).
