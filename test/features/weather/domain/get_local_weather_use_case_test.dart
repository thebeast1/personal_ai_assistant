import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_ai_assistant/core/network/error/failure.dart';
import 'package:personal_ai_assistant/core/use_cases/use_cases.dart';
import 'package:personal_ai_assistant/features/location/data/models/location_model.dart';
import 'package:personal_ai_assistant/features/location/domain/use_cases/get_current_location_use_case.dart';
import 'package:personal_ai_assistant/features/weather/data/models/geo_location_model.dart';
import 'package:personal_ai_assistant/features/weather/data/models/weather_model.dart';
import 'package:personal_ai_assistant/features/weather/domain/enums/weather_condition.dart';
import 'package:personal_ai_assistant/features/weather/domain/params/get_weather_params.dart';
import 'package:personal_ai_assistant/features/weather/domain/repositories/weather_repository.dart';
import 'package:personal_ai_assistant/features/weather/domain/use_cases/get_local_weather_use_case.dart';

class _MockGetCurrentLocation extends Mock
    implements GetCurrentLocationUseCase {}

class _MockWeatherRepository extends Mock implements WeatherRepository {}

void main() {
  const giza = LocationModel(
    latitude: 30.1,
    longitude: 31.2,
    name: 'Giza',
    country: 'Egypt',
  );
  const weather = WeatherModel(
    city: 'Giza',
    country: 'Egypt',
    temperatureC: 24,
    feelsLikeC: 25,
    humidity: 40,
    windKmh: 12,
    condition: WeatherCondition.clear,
  );

  late _MockGetCurrentLocation getLocation;
  late _MockWeatherRepository repository;
  late GetLocalWeatherUseCase useCase;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      const GeoLocationModel(name: '', country: '', latitude: 0, longitude: 0),
    );
    registerFallbackValue(GetWeatherParams(city: ''));
  });

  setUp(() {
    getLocation = _MockGetCurrentLocation();
    repository = _MockWeatherRepository();
    useCase = GetLocalWeatherUseCase(
      getCurrentLocationUseCase: getLocation,
      weatherRepository: repository,
    );
  });

  test('with a location: weather for those coordinates', () async {
    when(() => getLocation(any())).thenAnswer((_) async => const Right(giza));
    GeoLocationModel? asked;
    when(
      () => repository.getWeatherForPlace(place: any(named: 'place')),
    ).thenAnswer((call) async {
      asked = call.namedArguments[#place] as GeoLocationModel;
      return const Right(weather);
    });

    final result = await useCase(const NoParams());

    expect(result.getOrElse(() => throw 'expected Right'), weather);
    expect(asked?.latitude, 30.1);
    expect(asked?.longitude, 31.2);
    expect(asked?.name, 'Giza');
  });

  test('without a location: LocationFailure, and no city is guessed',
      () async {
    when(
      () => getLocation(any()),
    ).thenAnswer((_) async => Left(LocationFailure()));

    final result = await useCase(const NoParams());

    expect(result.fold((f) => f, (_) => null), isA<LocationFailure>());
    verifyNever(() => repository.getCurrentWeather(params: any(named: 'params')));
    verifyNever(() => repository.getWeatherForPlace(place: any(named: 'place')));
  });

  test('location OK but no internet: the failure', () async {
    when(() => getLocation(any())).thenAnswer((_) async => const Right(giza));
    when(
      () => repository.getWeatherForPlace(place: any(named: 'place')),
    ).thenAnswer((_) async => Left(NetworkFailure()));

    final result = await useCase(const NoParams());

    expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
  });
}
