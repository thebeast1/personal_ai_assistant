import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/error/failure.dart';
import '../../../../core/use_cases/use_cases.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../location/domain/use_cases/get_current_location_use_case.dart';
import '../../data/models/geo_location_model.dart';
import '../entities/local_weather_result.dart';
import '../enums/weather_source.dart';
import '../params/get_weather_params.dart';
import '../repositories/weather_repository.dart';

/// Weather where the user is, or for [AppConstants.defaultWeatherCity] when
/// the location can't be read (permission denied, location off, timeout).
///
/// Step two (see the local weather design doc): replace the default-city
/// branch with a failure that makes Gemma ask the user for their city.
@injectable
class GetLocalWeatherUseCase extends UseCase<LocalWeatherResult, NoParams> {
  GetLocalWeatherUseCase({
    required this.getCurrentLocationUseCase,
    required this.weatherRepository,
  });

  final GetCurrentLocationUseCase getCurrentLocationUseCase;
  final WeatherRepository weatherRepository;

  @override
  Future<Either<Failure, LocalWeatherResult>> call(NoParams params) async {
    final location = await getCurrentLocationUseCase(const NoParams());

    return location.fold(
      (_) async {
        final weather = await weatherRepository.getCurrentWeather(
          params: GetWeatherParams(city: AppConstants.defaultWeatherCity),
        );
        return weather.map(
          (w) => LocalWeatherResult(
            weather: w,
            source: WeatherSource.defaultCity,
          ),
        );
      },
      (loc) async {
        // No Cairo retry on failure here: if the location worked, a weather
        // failure (e.g. no internet) would hit Cairo too.
        final weather = await weatherRepository.getWeatherForPlace(
          place: GeoLocationModel(
            name: loc.name,
            country: loc.country,
            latitude: loc.latitude,
            longitude: loc.longitude,
          ),
        );
        return weather.map(
          (w) => LocalWeatherResult(
            weather: w,
            source: WeatherSource.currentLocation,
          ),
        );
      },
    );
  }
}
