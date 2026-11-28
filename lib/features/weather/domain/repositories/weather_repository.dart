import 'package:dartz/dartz.dart';

import '../../../../core/network/error/failure.dart';
import '../../data/models/geo_location_model.dart';
import '../../data/models/weather_model.dart';
import '../params/get_weather_params.dart';

abstract class WeatherRepository {
  Future<Either<Failure, WeatherModel>> getCurrentWeather({
    required GetWeatherParams params,
  });

  /// For coordinates the app already has, such as the user's location.
  Future<Either<Failure, WeatherModel>> getWeatherForPlace({
    required GeoLocationModel place,
  });
}
