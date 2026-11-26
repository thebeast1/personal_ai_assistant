import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_ai_assistant/core/network/error/app_exceptions.dart';
import 'package:personal_ai_assistant/core/network/error/failure.dart';
import 'package:personal_ai_assistant/features/weather/data/data_sources/weather_remote_data_source.dart';
import 'package:personal_ai_assistant/features/weather/data/models/geo_location_model.dart';
import 'package:personal_ai_assistant/features/weather/data/models/weather_model.dart';
import 'package:personal_ai_assistant/features/weather/data/repositories/weather_repository_impl.dart';
import 'package:personal_ai_assistant/features/weather/domain/enums/weather_condition.dart';
import 'package:personal_ai_assistant/features/weather/domain/params/get_weather_params.dart';

class _MockRemote extends Mock implements WeatherRemoteDataSource {}

void main() {
  const place = GeoLocationModel(
    name: 'Cairo',
    country: 'Egypt',
    latitude: 30,
    longitude: 31,
  );
  const weather = WeatherModel(
    city: 'Cairo',
    country: 'Egypt',
    temperatureC: 24,
    feelsLikeC: 25,
    humidity: 40,
    windKmh: 12,
    condition: WeatherCondition.clear,
  );
  final params = GetWeatherParams(city: 'Cairo');

  late _MockRemote remote;
  late WeatherRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(params);
    registerFallbackValue(place);
  });

  setUp(() {
    remote = _MockRemote();
    repository = WeatherRepositoryImpl(weatherRemoteDataSource: remote);
  });

  test('finds the city, then returns its weather', () async {
    when(
      () => remote.searchCity(params: any(named: 'params')),
    ).thenAnswer((_) async => place);
    when(
      () => remote.getCurrentWeather(place: place),
    ).thenAnswer((_) async => weather);

    final result = await repository.getCurrentWeather(params: params);

    expect(result.getOrElse(() => throw 'expected Right'), weather);
  });

  Future<Failure> failureFor(Object error) async {
    when(
      () => remote.searchCity(params: any(named: 'params')),
    ).thenThrow(error);
    final result = await repository.getCurrentWeather(params: params);
    return result.fold((f) => f, (_) => throw 'expected Left');
  }

  test('an unknown city becomes NotFoundFailure', () async {
    expect(
      await failureFor(const NotFoundException('No city')),
      isA<NotFoundFailure>(),
    );
  });

  test('no internet becomes NetworkFailure', () async {
    expect(
      await failureFor(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ),
      ),
      isA<NetworkFailure>(),
    );
  });

  test('anything else becomes ServerFailure', () async {
    expect(await failureFor(const FormatException('bad')), isA<ServerFailure>());
  });
}
