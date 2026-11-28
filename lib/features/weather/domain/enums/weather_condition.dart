enum WeatherCondition {
  clear,
  partlyCloudy,
  cloudy,
  fog,
  drizzle,
  rain,
  snow,
  thunderstorm,
  unknown;

  /// Maps a WMO weather code, as Open-Meteo returns it, to a condition.
  static WeatherCondition fromWmoCode(int code) => switch (code) {
    0 => clear,
    1 || 2 => partlyCloudy,
    3 => cloudy,
    45 || 48 => fog,
    >= 51 && <= 57 => drizzle,
    (>= 61 && <= 67) || (>= 80 && <= 82) => rain,
    (>= 71 && <= 77) || 85 || 86 => snow,
    >= 95 && <= 99 => thunderstorm,
    _ => unknown,
  };

  static WeatherCondition fromName(String? name) =>
      values.asNameMap()[name] ?? unknown;
}
