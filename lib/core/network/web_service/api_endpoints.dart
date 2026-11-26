/// Full URLs of the external APIs the app's tools call.
abstract final class ApiEndpoints {
  /// City name → coordinates. Free, no API key.
  static const openMeteoGeocoding =
      'https://geocoding-api.open-meteo.com/v1/search';

  /// Coordinates → current weather. Free, no API key.
  static const openMeteoForecast = 'https://api.open-meteo.com/v1/forecast';
}
