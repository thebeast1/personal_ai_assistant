import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/error/failure.dart';
import '../../../../core/use_cases/use_cases.dart';
import '../../data/models/weather_model.dart';
import '../params/get_weather_params.dart';
import '../repositories/weather_repository.dart';

@injectable
class GetCurrentWeatherUseCase extends UseCase<WeatherModel, GetWeatherParams> {
  GetCurrentWeatherUseCase({required this.weatherRepository});

  final WeatherRepository weatherRepository;

  @override
  Future<Either<Failure, WeatherModel>> call(GetWeatherParams params) async =>
      await weatherRepository.getCurrentWeather(params: params);
}
