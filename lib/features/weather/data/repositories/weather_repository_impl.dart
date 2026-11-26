import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/error/error_handler.dart';
import '../../../../core/network/error/failure.dart';
import '../../domain/params/get_weather_params.dart';
import '../../domain/repositories/weather_repository.dart';
import '../data_sources/weather_remote_data_source.dart';
import '../models/geo_location_model.dart';
import '../models/weather_model.dart';

@Injectable(as: WeatherRepository)
class WeatherRepositoryImpl implements WeatherRepository {
  WeatherRepositoryImpl({required this.weatherRemoteDataSource});

  final WeatherRemoteDataSource weatherRemoteDataSource;

  @override
  Future<Either<Failure, WeatherModel>> getCurrentWeather({
    required GetWeatherParams params,
  }) async {
    try {
      final place = await weatherRemoteDataSource.searchCity(params: params);
      final weather = await weatherRemoteDataSource.getCurrentWeather(
        place: place,
      );
      return Right(weather);
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }

  @override
  Future<Either<Failure, WeatherModel>> getWeatherForPlace({
    required GeoLocationModel place,
  }) async {
    try {
      return Right(
        await weatherRemoteDataSource.getCurrentWeather(place: place),
      );
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }
}
