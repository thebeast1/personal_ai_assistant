# Weather for my location: design

Date: 2026-11-26
Status: approved (2026-11-26)
Builds on: `docs/superpowers/specs/2026-11-26-ai-tools-architecture-design.md`

## Intent

When the user asks about the weather without naming a place, Khadeja uses the
phone's location. If she can't get it, she uses Cairo. Asking by city name
keeps working as it does today.

## Behaviour

1. The user asks "What's the weather?" or "Do I need an umbrella?" with no
   place named. Gemma calls `get_local_weather`, which takes no arguments.
2. The tool asks for location permission **at that moment**: the first time,
   or again if it was denied but can still be asked. Nothing is asked at app
   start.
3. **Location available:** it reads the current lat/lng (low accuracy,
   5 s timeout), gets the weather for those coordinates, and turns them into
   a place name with the phone's geocoder.
4. **No location** (permission denied or denied forever, location services
   off, timeout, any error): it gets the weather for **Cairo**, through the
   existing city lookup.
5. The result includes `"source": "current_location"` or
   `"source": "default_city"`, so Gemma can say "I couldn't get your location,
   so here's Cairo." The weather card looks the same either way.
6. When the user names a city ("weather in London"), Gemma uses
   `get_weather(city)` as today. A named city always wins over location.

## Non-goals

- Background location, or tracking location continuously.
- Remembering the last location between launches.
- A settings screen for the default city. It's a constant.
- Asking for location at startup.

## Approaches considered

1. **Separate `get_local_weather` tool with no arguments (chosen).** A small
   model reliably picks between two clearly described tools. It also shows
   the toolbox growing to 2 tools.
2. **Optional `city` in `get_weather`.** Gemma 4 E2B tends to fill in
   `city: "my location"` or guess a city, which then fails geocoding.

## Design

### New `location` feature (reusable by future tools)

```
features/location/
├── data/
│   ├── data_sources/location_data_source.dart   geolocator + geocoding
│   ├── models/location_model.dart               latitude, longitude, name, country
│   └── repositories/location_repository_impl.dart
└── domain/
    ├── repositories/location_repository.dart
    └── use_cases/get_current_location_use_case.dart   UseCase<LocationModel, NoParams>
```

- `LocationDataSource.getCurrentLocation()`:
  - If location services are off, it throws `LocationUnavailableException`.
  - It then checks the permission. When the result is `denied`, it calls
    `Geolocator.requestPermission()`. That's when the system dialog appears.
  - If the permission ends up `denied` or `deniedForever`, it throws
    `LocationPermissionDeniedException`.
  - It reads the position with `LocationAccuracy.low` and a 5 s time limit.
    A timeout throws `LocationUnavailableException`.
  - It reverse-geocodes with `placemarkFromCoordinates`, using `locality`
    first, then `subAdministrativeArea`, then `administrativeArea`. If that
    fails, it still returns the coordinates, with an empty name.
- The new exceptions go in `core/network/error/app_exceptions.dart`, with a
  `LocationFailure` in `failure.dart` that `ErrorHandler` maps them to.
- Permissions and location go through `geolocator` alone, not
  `permission_handler`. That way iOS doesn't need extra Podfile permission
  macros.

### Weather feature additions

- `GeoLocationModel` already holds name, country, lat and lon, so the
  location turns into one directly and the existing
  `WeatherRemoteDataSource.getCurrentWeather(place:)` is reused unchanged.
- `domain/use_cases/get_local_weather_use_case.dart`:
  `UseCase<LocalWeatherResult, NoParams>`. It calls
  `GetCurrentLocationUseCase`. On `Right`, it gets the weather for that place
  with `source = currentLocation`. On `Left`, it calls
  `WeatherRepository.getCurrentWeather(GetWeatherParams(city: AppConstants.defaultWeatherCity))`
  with `source = defaultCity`. A weather failure on either path is returned
  as is.
- `LocalWeatherResult { WeatherModel weather; WeatherSource source; }` and
  `enum WeatherSource { currentLocation, defaultCity }`.
- `WeatherRepository` gets `getWeatherForPlace({required GeoLocationModel place})`
  for the coordinates path.
- `tool/get_local_weather_tool.dart`:
  - name: `get_local_weather`
  - description: "Get the current weather where the user is. Use when the
    user asks about the weather, temperature or an umbrella without naming a
    city."
  - parameters: an empty object
  - result: `weather.toJson()` plus
    `'source': 'current_location' | 'default_city'`. Failures map the same way
    as `get_weather`.
- `ToolsInjection`: `ToolRegistry([getWeatherTool, getLocalWeatherTool])`, and
  `ToolResultViews` maps both names to `WeatherCard`.
- Update the `get_weather` description so it says it's for when the user
  names a city.

### Platform setup

- Android: `<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>`.
- iOS `Info.plist`: `NSLocationWhenInUseUsageDescription`, with the text "Khadeja
  uses your location to show the weather where you are."
- `AppConstants.defaultWeatherCity = 'Cairo'`.
- Packages: `geolocator`, `geocoding`.

### Privacy

The location is read only when this tool runs. Only lat/lng go to Open-Meteo.
The place name comes from the phone's own geocoder. The README says so.

### Testing

- `LocationRepositoryImpl`: the exceptions map to `LocationFailure`.
- `GetLocalWeatherUseCase` (with mocks):
  - location OK → weather for that place, `currentLocation`
  - location failure → Cairo, `defaultCity`
  - weather failure on either path → `Left`
- `GetLocalWeatherTool`: success map includes `source`, failure codes, and an
  empty `required` list.
- `LocationDataSource` stays thin and is checked on a device. The plugin
  calls aren't unit-tested.
- On a device:
  - first weather question → permission prompt → allow → local card
  - deny → Cairo card and Gemma says so
  - "weather in London" → London
  - location services off → Cairo

## Future: step two (not built now)

Replace the Cairo placeholder with the user's own city when the location
can't be read:

1. When `get_local_weather` can't get a location, it returns
   `ToolFailure(code: 'location_unavailable', message: 'Ask the user which city they are in.')`
   instead of falling back to Cairo.
2. Gemma asks: "I couldn't get your location. Which city are you in?"
3. The user types a city, and Gemma calls `get_weather(city)`, which already
   exists.
4. Optional: remember that city (in `shared_preferences`) as the fallback for
   later questions, so the user is asked only once.

Step one keeps this cheap. The fallback lives in one place
(`GetLocalWeatherUseCase`), and `get_weather(city)` already handles typed
cities. Step two mostly means swapping the Cairo branch for the failure above
and updating the system prompt.

## Calls made by Claude

- Low accuracy, 5 s timeout, and `geolocator` instead of `permission_handler`.
- `location` is its own feature instead of living inside weather.
- When reverse geocoding fails, the coordinates are still used, with an empty
  name.
