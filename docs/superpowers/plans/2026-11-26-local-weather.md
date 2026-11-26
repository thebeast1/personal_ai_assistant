# Weather for My Location Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `get_local_weather` tool that asks for location permission when it runs, uses the phone's lat/lng, and falls back to Cairo.

**Architecture:** A new reusable `features/location` feature (geolocator + geocoding) feeds a new `GetLocalWeatherUseCase` in the weather feature. A no-argument `GetLocalWeatherTool` returns the same weather map plus a `source` field, and is registered next to `get_weather` in `ToolsInjection`.

**Tech Stack:** Flutter 3.50 (`~/Developer/flutter-3-50-0/bin/flutter`), geolocator, geocoding, dartz, get_it + injectable, mocktail.

**Spec:** `docs/superpowers/specs/2026-11-26-local-weather-design.md`

## Global Constraints

- Follow the mismar conventions in `docs/superpowers/plans/2026-11-26-ai-tools-weather.md` ("Conventions"): `data_sources/`, `use_cases/`, `*UseCase extends UseCase<T, P>` with `@injectable`, repositories catch and return `Left(ErrorHandler.handle(e).failure)`, and models use `const` constructors with `fromJson`.
- The permission is requested only inside `get_local_weather`, never at startup.
- Use `geolocator` for permissions, not `permission_handler`. Don't add Podfile macros.
- `LocationAccuracy.low`, with a 5 s time limit on the position.
- Fallback city: `AppConstants.defaultWeatherCity = 'Cairo'`.
- Tool name `get_local_weather`. The result is `WeatherModel.toJson()` plus `'source': 'current_location' | 'default_city'`.
- Failure codes stay the same as `get_weather`: `NotFoundFailure` → `city_not_found`, `NetworkFailure` → `no_internet`, anything else → `service_unavailable`.
- `features/location` must not import `features/weather`. `features/chat` must not import either.
- After any `@injectable` change, run `~/Developer/flutter-3-50-0/bin/dart run build_runner build --delete-conflicting-outputs`.

## Review Focus

1. Permission denied forever: no second prompt, Cairo is used, and nothing throws (Task 2).
2. Location services off: Cairo, with no permission prompt (Task 1 data source order, Task 2).
3. Position timeout after 5 s: Cairo, and the reply isn't stuck (Tasks 1, 2).
4. Reverse geocoding fails or returns no placemarks: the coordinates are still used and the name is empty, so the card shows only the country or nothing, without crashing (Task 1, plus `WeatherCard` already joins only non-empty parts).
5. No internet with location available: `no_internet` is returned, with no silent switch to Cairo, because Cairo would fail too (Task 2).

---

### Task 1: Location feature

**Files:**
- Modify: `pubspec.yaml` (`flutter pub add geolocator geocoding`)
- Modify: `android/app/src/main/AndroidManifest.xml` (add `ACCESS_COARSE_LOCATION` next to the other permissions)
- Modify: `ios/Runner/Info.plist` (add `NSLocationWhenInUseUsageDescription` = `Khadeja uses your location to show the weather where you are.`)
- Modify: `lib/core/network/error/app_exceptions.dart`, `lib/core/network/error/failure.dart`, `lib/core/network/error/error_handler.dart`
- Create: `lib/features/location/data/models/location_model.dart`
- Create: `lib/features/location/data/data_sources/location_data_source.dart`
- Create: `lib/features/location/data/repositories/location_repository_impl.dart`
- Create: `lib/features/location/domain/repositories/location_repository.dart`
- Create: `lib/features/location/domain/use_cases/get_current_location_use_case.dart`
- Test: `test/core/network/error_handler_test.dart` (extend), `test/features/location/data/location_repository_impl_test.dart`

**Interfaces:**
- Produces:
  - `class LocationPermissionDeniedException implements Exception` and `class LocationUnavailableException implements Exception` (both `const`, with an optional `message`)
  - `class LocationFailure extends Failure`, with message `'The location is not available.'`. `ErrorHandler` maps both exceptions to it.
  - `class LocationModel { final double latitude; final double longitude; final String name; final String country; const LocationModel({...}); }`
  - `abstract class LocationDataSource { Future<LocationModel> getCurrentLocation(); }` and `@Injectable(as: LocationDataSource) class LocationDataSourceImpl`
  - `abstract class LocationRepository { Future<Either<Failure, LocationModel>> getCurrentLocation(); }` and `@Injectable(as: LocationRepository) class LocationRepositoryImpl({required LocationDataSource locationDataSource})`
  - `@injectable class GetCurrentLocationUseCase extends UseCase<LocationModel, NoParams>({required LocationRepository locationRepository})`

`LocationDataSourceImpl.getCurrentLocation()` order (exact):
1. `if (!await Geolocator.isLocationServiceEnabled()) throw const LocationUnavailableException();`
2. `var permission = await Geolocator.checkPermission(); if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();`
3. `if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw const LocationPermissionDeniedException();`
4. `Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 5)))`. Catch `TimeoutException` → `LocationUnavailableException`.
5. `placemarkFromCoordinates(lat, lng)` in its own `try`. Name = the first non-empty of `locality`, `subAdministrativeArea`, `administrativeArea`; country = `country`. On any error or an empty list, name = `''` and country = `''`.

- [ ] **Step 1: Add the packages and platform permissions**

Run: `~/Developer/flutter-3-50-0/bin/flutter pub add geolocator geocoding`
Expected: `pubspec.yaml` updated. Then add the manifest line and the plist key above.

- [ ] **Step 2: Write the failing tests**

`error_handler_test.dart`, new cases:
- `ErrorHandler.handle(const LocationPermissionDeniedException()).failure` is a `LocationFailure`
- `ErrorHandler.handle(const LocationUnavailableException()).failure` is a `LocationFailure`

`location_repository_impl_test.dart` (mock `LocationDataSource`):
- success → `Right(model)` (the same instance)
- `LocationPermissionDeniedException` → `Left(LocationFailure)`
- `LocationUnavailableException` → `Left(LocationFailure)`

- [ ] **Step 3: Run the tests to verify they fail**

Run: `~/Developer/flutter-3-50-0/bin/flutter test test/core/network test/features/location`
Expected: FAIL, missing types

- [ ] **Step 4: Implement the files listed under Interfaces, then run codegen**

- [ ] **Step 5: Run the tests to verify they pass**

Run: `~/Developer/flutter-3-50-0/bin/flutter test test/core test/features/location`
Expected: all PASS

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist lib/core lib/features/location test/core test/features/location
git commit -m "feat(location): add location feature with on-demand permission"
```

---

### Task 2: Local weather use case

**Files:**
- Modify: `lib/core/utils/app_constants.dart` (`static const defaultWeatherCity = 'Cairo';`)
- Modify: `lib/features/weather/domain/repositories/weather_repository.dart` and `lib/features/weather/data/repositories/weather_repository_impl.dart`
- Create: `lib/features/weather/domain/enums/weather_source.dart`
- Create: `lib/features/weather/domain/entities/local_weather_result.dart`
- Create: `lib/features/weather/domain/use_cases/get_local_weather_use_case.dart`
- Test: `test/features/weather/data/weather_repository_impl_test.dart` (extend), `test/features/weather/domain/get_local_weather_use_case_test.dart`

**Interfaces:**
- Consumes: `GetCurrentLocationUseCase`, `LocationModel` (Task 1). `WeatherRepository`, `GeoLocationModel`, `GetWeatherParams` (existing)
- Produces:
  - `WeatherRepository.getWeatherForPlace({required GeoLocationModel place})` → `Future<Either<Failure, WeatherModel>>`. The impl calls `weatherRemoteDataSource.getCurrentWeather(place: place)` in the standard try/catch.
  - `enum WeatherSource { currentLocation, defaultCity }`, with `String get apiName` returning `'current_location'` / `'default_city'`
  - `class LocalWeatherResult { final WeatherModel weather; final WeatherSource source; const LocalWeatherResult({...}); }`
  - `@injectable class GetLocalWeatherUseCase extends UseCase<LocalWeatherResult, NoParams>({required GetCurrentLocationUseCase getCurrentLocationUseCase, required WeatherRepository weatherRepository})`

`GetLocalWeatherUseCase.call` logic: get the location. On `Right(loc)` →
`weatherRepository.getWeatherForPlace(place: GeoLocationModel(name: loc.name, country: loc.country, latitude: loc.latitude, longitude: loc.longitude))`,
mapped to `LocalWeatherResult(source: currentLocation)`. On `Left` →
`weatherRepository.getCurrentWeather(params: GetWeatherParams(city: AppConstants.defaultWeatherCity))`,
mapped to `LocalWeatherResult(source: defaultCity)`. A weather `Left` on either path is returned unchanged. When the location worked but the weather call failed, there's no second attempt with Cairo.

- [ ] **Step 1: Write the failing tests**

`weather_repository_impl_test.dart`:
- `getWeatherForPlace(place: place)` → `Right(weather)` and calls `getCurrentWeather(place: place)`. A `DioException(connectionError)` → `Left(NetworkFailure)`.

`get_local_weather_use_case_test.dart` (mock `GetCurrentLocationUseCase` and `WeatherRepository`; `registerFallbackValue` for `NoParams`, `GeoLocationModel`, `GetWeatherParams`):
- location `Right(LocationModel(latitude: 30.1, longitude: 31.2, name: 'Giza', country: 'Egypt'))` → `getWeatherForPlace` is called with lat `30.1`, lon `31.2`, name `'Giza'`. The result's `source == WeatherSource.currentLocation`. `getCurrentWeather` is never called.
- location `Left(LocationFailure())` → `getCurrentWeather` is called with `city == 'Cairo'`, and `source == WeatherSource.defaultCity`
- location OK but `getWeatherForPlace` → `Left(NetworkFailure())`: the result is `Left(NetworkFailure)` and `getCurrentWeather` is never called
- location failure and Cairo → `Left(ServerFailure())`: the result is `Left(ServerFailure)`
- `WeatherSource.currentLocation.apiName == 'current_location'` and `WeatherSource.defaultCity.apiName == 'default_city'`

- [ ] **Step 2: Run the tests to verify they fail**

Run: `~/Developer/flutter-3-50-0/bin/flutter test test/features/weather`
Expected: FAIL, missing members

- [ ] **Step 3: Implement the interfaces, then run codegen**

- [ ] **Step 4: Run the tests to verify they pass**

Run: `~/Developer/flutter-3-50-0/bin/flutter test test/features/weather`
Expected: all PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/app_constants.dart lib/features/weather lib/core/services test/features/weather
git commit -m "feat(weather): add local weather use case with Cairo fallback"
```

---

### Task 3: `get_local_weather` tool, registration, docs

**Files:**
- Create: `lib/features/weather/tool/get_local_weather_tool.dart`
- Modify: `lib/features/weather/tool/get_weather_tool.dart` (description only)
- Modify: `lib/core/services/injection.dart` (`ToolsInjection`)
- Modify: `README.md` (Tools section, privacy line)
- Test: `test/features/weather/tool/get_local_weather_tool_test.dart`

**Interfaces:**
- Consumes: `GetLocalWeatherUseCase`, `LocalWeatherResult`, `WeatherSource` (Task 2)
- Produces: `@injectable class GetLocalWeatherTool extends AppTool({required GetLocalWeatherUseCase getLocalWeatherUseCase})`, with `static const toolName = 'get_local_weather'`

Tool definition (exact):
```dart
const Tool(
  name: 'get_local_weather',
  description: 'Get the current weather where the user is. Use when the user '
      'asks about the weather, temperature or an umbrella without naming a city.',
  parameters: {'type': 'object', 'properties': {}, 'required': []},
)
```

New `get_weather` description (exact): `'Get the current weather for a city the user names. Use only when the user mentions a specific city.'`

The failure code mapping is the same as `GetWeatherTool._code`. Move it to a shared top-level `String weatherFailureCode(Failure failure)` in `lib/features/weather/tool/weather_failure_code.dart` and use it from both tools.

- [ ] **Step 1: Write the failing test**

`get_local_weather_tool_test.dart` (mock `GetLocalWeatherUseCase`):
- `definition.name == 'get_local_weather'` and `definition.parameters['required']` is empty
- `Right(LocalWeatherResult(weather: w, source: WeatherSource.currentLocation))` → `ToolSuccess` data equals `{...w.toJson(), 'source': 'current_location'}`
- `source: defaultCity` → `data['source'] == 'default_city'` and `data['city'] == w.city`
- `Left(NetworkFailure())` → `code == 'no_internet'`. `Left(NotFoundFailure())` → `city_not_found`. `Left(ServerFailure())` → `service_unavailable`
- `execute({})` and `execute({'city': 'ignored'})` both call the use case once

The existing `get_weather_tool_test.dart` must still pass after the `weatherFailureCode` refactor.

- [ ] **Step 2: Run the test to verify it fails**

Run: `~/Developer/flutter-3-50-0/bin/flutter test test/features/weather/tool`
Expected: FAIL, missing file

- [ ] **Step 3: Implement the tool and `weatherFailureCode`, update the `get_weather` description, and register in `ToolsInjection`**

`ToolsInjection`:
- `ToolRegistry toolRegistry(GetWeatherTool getWeatherTool, GetLocalWeatherTool getLocalWeatherTool) => ToolRegistry([getWeatherTool, getLocalWeatherTool]);`
- `ToolResultViews` maps both `GetWeatherTool.toolName` and `GetLocalWeatherTool.toolName` to `WeatherCard(data: data)`

Then run codegen.

- [ ] **Step 4: Update the README**

In the Tools section, add `get_local_weather`. It asks for location permission the first time you ask about the weather without a city, sends only lat/lng to Open-Meteo, gets the place name from the phone's geocoder, and falls back to Cairo. Add `geolocator` and `geocoding` to the tech stack, and `ACCESS_COARSE_LOCATION` and `NSLocationWhenInUseUsageDescription` to the platform setup.

- [ ] **Step 5: Run everything**

Run: `~/Developer/flutter-3-50-0/bin/flutter analyze && ~/Developer/flutter-3-50-0/bin/flutter test`
Expected: `No issues found!`, all PASS

Run: `grep -rn "features/weather\|features/location" lib/features/chat; grep -rn "features/weather" lib/features/location`
Expected: no output

- [ ] **Step 6: Commit**

```bash
git add lib test README.md
git commit -m "feat(weather): add get_local_weather tool"
```

---

### Task 4: On-device check

**Files:** none (fix anything found in the owning task's files)

- [ ] **Step 1: `flutter run` on a real phone, then check each case:**
  - Fresh install: the app starts with **no** location prompt
  - "What's the weather?" → permission prompt → Allow → a card with your area's name, and a reply about it
  - "What's the weather?" again → no prompt, local card
  - Reinstall, then Deny → Cairo card, and Gemma mentions she couldn't get your location
  - Location services off → Cairo, no prompt
  - "Weather in London" → London card (`get_weather`), no location prompt
  - Airplane mode → no card, she says there's no internet, and the spinner stops

Expected: as listed. Note any case where Gemma picks the wrong tool, with its exact wording.
