import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/error/failure.dart';
import '../../../../core/use_cases/use_cases.dart';
import '../../../location/domain/use_cases/get_current_location_use_case.dart';
import '../../data/models/geo_location_model.dart';
import '../../data/models/weather_model.dart';
import '../repositories/weather_repository.dart';

/// Weather where the user is.
///
/// When the location can't be read (permission denied, location off,
/// timeout) it returns that [LocationFailure] instead of guessing a city:
/// the tool then asks Gemma to ask the user which city they're in.
@injectable
class GetLocalWeatherUseCase extends UseCase<WeatherModel, NoParams> {
  GetLocalWeatherUseCase({
    required this.getCurrentLocationUseCase,
    required this.weatherRepository,
  });

  final GetCurrentLocationUseCase getCurrentLocationUseCase;
  final WeatherRepository weatherRepository;

  @override
  Future<Either<Failure, WeatherModel>> call(NoParams params) async {
    final location = await getCurrentLocationUseCase(const NoParams());

    return location.fold(
      (failure) async => Left(failure),
      (loc) => weatherRepository.getWeatherForPlace(
        place: GeoLocationModel(
          name: loc.name,
          country: loc.country,
          latitude: loc.latitude,
          longitude: loc.longitude,
        ),
      ),
    );
  }
}
