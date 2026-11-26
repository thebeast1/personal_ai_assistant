/// Where the local weather came from. Sent to Gemma so she can tell the user
/// when it fell back to the default city.
enum WeatherSource {
  currentLocation('current_location'),
  defaultCity('default_city');

  const WeatherSource(this.apiName);

  final String apiName;
}
