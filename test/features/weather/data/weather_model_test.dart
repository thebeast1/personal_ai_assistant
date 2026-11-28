import 'package:flutter_test/flutter_test.dart';
import 'package:personal_ai_assistant/features/weather/data/models/geo_location_model.dart';
import 'package:personal_ai_assistant/features/weather/data/models/weather_model.dart';
import 'package:personal_ai_assistant/features/weather/domain/enums/weather_condition.dart';

import '../../../helpers/fixture.dart';

void main() {
  final cairo = GeoLocationModel.fromJson(
    (fixture('open_meteo_geocoding_cairo.json')['results'] as List).first,
  );

  test('GeoLocationModel reads name, country and coordinates', () {
    expect(cairo.name, 'Cairo');
    expect(cairo.country, 'Egypt');
    expect(cairo.latitude, 30.06263);
    expect(cairo.longitude, 31.24967);
  });

  test('WeatherModel.fromApiJson combines the place with current weather', () {
    final weather = WeatherModel.fromApiJson(
      fixture('open_meteo_current.json')['current'],
      place: cairo,
    );

    expect(weather.city, 'Cairo');
    expect(weather.country, 'Egypt');
    expect(weather.temperatureC, 16.3);
    expect(weather.feelsLikeC, 15.7);
    expect(weather.humidity, 74);
    expect(weather.windKmh, 7.6);
    expect(weather.condition, WeatherCondition.partlyCloudy);
  });

  test('toJson is what the model reads, and fromJson reads it back', () {
    const weather = WeatherModel(
      city: 'Cairo',
      country: 'Egypt',
      temperatureC: 24,
      feelsLikeC: 25,
      humidity: 40,
      windKmh: 12,
      condition: WeatherCondition.clear,
    );

    expect(weather.toJson(), {
      'city': 'Cairo',
      'country': 'Egypt',
      'temperature_c': 24.0,
      'feels_like_c': 25.0,
      'humidity': 40,
      'wind_kmh': 12.0,
      'condition': 'clear',
    });
    expect(WeatherModel.fromJson(weather.toJson()).toJson(), weather.toJson());
  });

  test('WMO weather codes map to conditions', () {
    const cases = {
      0: WeatherCondition.clear,
      2: WeatherCondition.partlyCloudy,
      3: WeatherCondition.cloudy,
      48: WeatherCondition.fog,
      53: WeatherCondition.drizzle,
      81: WeatherCondition.rain,
      86: WeatherCondition.snow,
      96: WeatherCondition.thunderstorm,
      42: WeatherCondition.unknown,
    };
    cases.forEach((code, condition) {
      expect(WeatherCondition.fromWmoCode(code), condition, reason: '$code');
    });
  });
}
