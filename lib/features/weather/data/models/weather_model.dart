import '../../domain/enums/weather_condition.dart';
import 'geo_location_model.dart';

class WeatherModel {
  final String city;
  final String country;
  final double temperatureC;
  final double feelsLikeC;
  final int humidity;
  final double windKmh;
  final WeatherCondition condition;

  const WeatherModel({
    required this.city,
    required this.country,
    required this.temperatureC,
    required this.feelsLikeC,
    required this.humidity,
    required this.windKmh,
    required this.condition,
  });

  /// From Open-Meteo's `current` object, plus the place it was asked for.
  factory WeatherModel.fromApiJson(
    Map<String, dynamic> current, {
    required GeoLocationModel place,
  }) => WeatherModel(
    city: place.name,
    country: place.country,
    temperatureC: (current['temperature_2m'] as num).toDouble(),
    feelsLikeC: (current['apparent_temperature'] as num).toDouble(),
    humidity: (current['relative_humidity_2m'] as num).toInt(),
    windKmh: (current['wind_speed_10m'] as num).toDouble(),
    condition: WeatherCondition.fromWmoCode(
      (current['weather_code'] as num).toInt(),
    ),
  );

  /// The tool's result: what Gemma reads and what the weather card shows.
  Map<String, dynamic> toJson() => {
    'city': city,
    'country': country,
    'temperature_c': temperatureC,
    'feels_like_c': feelsLikeC,
    'humidity': humidity,
    'wind_kmh': windKmh,
    'condition': condition.name,
  };

  /// Reads [toJson]'s output back, for the weather card.
  factory WeatherModel.fromJson(Map<String, dynamic> json) => WeatherModel(
    city: json['city'] ?? '',
    country: json['country'] ?? '',
    temperatureC: (json['temperature_c'] as num? ?? 0).toDouble(),
    feelsLikeC: (json['feels_like_c'] as num? ?? 0).toDouble(),
    humidity: (json['humidity'] as num? ?? 0).toInt(),
    windKmh: (json['wind_kmh'] as num? ?? 0).toDouble(),
    condition: WeatherCondition.fromName(json['condition']),
  );
}
