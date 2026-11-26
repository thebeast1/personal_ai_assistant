import '../../data/models/weather_model.dart';
import '../enums/weather_source.dart';

class LocalWeatherResult {
  final WeatherModel weather;
  final WeatherSource source;

  const LocalWeatherResult({required this.weather, required this.source});
}
