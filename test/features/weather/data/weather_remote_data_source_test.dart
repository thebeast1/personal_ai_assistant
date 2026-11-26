import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_ai_assistant/core/network/error/app_exceptions.dart';
import 'package:personal_ai_assistant/core/network/web_service/api_endpoints.dart';
import 'package:personal_ai_assistant/core/network/web_service/network_helper.dart';
import 'package:personal_ai_assistant/features/weather/data/data_sources/weather_remote_data_source.dart';
import 'package:personal_ai_assistant/features/weather/data/models/geo_location_model.dart';
import 'package:personal_ai_assistant/features/weather/domain/params/get_weather_params.dart';

import '../../../helpers/fixture.dart';

class _MockNetworkHelper extends Mock implements NetworkHelper {}

void main() {
  late _MockNetworkHelper network;
  late WeatherRemoteDataSource dataSource;

  setUp(() {
    network = _MockNetworkHelper();
    dataSource = WeatherRemoteDataSourceImpl(networkHelper: network);
  });

  void respond(String url, Object response) => when(
    () => network.get(url: url, queryParams: any(named: 'queryParams')),
  ).thenAnswer((_) async => response);

  group('searchCity', () {
    test('asks the geocoding API for one English match', () async {
      respond(
        ApiEndpoints.openMeteoGeocoding,
        fixture('open_meteo_geocoding_cairo.json'),
      );

      final place = await dataSource.searchCity(
        params: GetWeatherParams(city: 'Cairo'),
      );

      expect(place.name, 'Cairo');
      verify(
        () => network.get(
          url: ApiEndpoints.openMeteoGeocoding,
          queryParams: {'name': 'Cairo', 'count': 1, 'language': 'en'},
        ),
      ).called(1);
    });

    test('an Arabic city name is looked up in Arabic', () async {
      respond(
        ApiEndpoints.openMeteoGeocoding,
        fixture('open_meteo_geocoding_cairo.json'),
      );

      await dataSource.searchCity(params: GetWeatherParams(city: 'القاهرة'));

      verify(
        () => network.get(
          url: ApiEndpoints.openMeteoGeocoding,
          queryParams: {'name': 'القاهرة', 'count': 1, 'language': 'ar'},
        ),
      ).called(1);
    });

    test('no results key means NotFoundException', () async {
      respond(
        ApiEndpoints.openMeteoGeocoding,
        fixture('open_meteo_geocoding_empty.json'),
      );

      expect(
        () => dataSource.searchCity(params: GetWeatherParams(city: 'Blorptown')),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('network errors bubble up for the repository to handle', () {
      when(
        () => network.get(
          url: any(named: 'url'),
          queryParams: any(named: 'queryParams'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => dataSource.searchCity(params: GetWeatherParams(city: 'Cairo')),
        throwsA(isA<DioException>()),
      );
    });
  });

  test('getCurrentWeather asks for the current fields of the place', () async {
    respond(ApiEndpoints.openMeteoForecast, fixture('open_meteo_current.json'));
    const place = GeoLocationModel(
      name: 'Cairo',
      country: 'Egypt',
      latitude: 30.06263,
      longitude: 31.24967,
    );

    final weather = await dataSource.getCurrentWeather(place: place);

    expect(weather.city, 'Cairo');
    expect(weather.temperatureC, 16.3);
    verify(
      () => network.get(
        url: ApiEndpoints.openMeteoForecast,
        queryParams: {
          'latitude': 30.06263,
          'longitude': 31.24967,
          'current':
              'temperature_2m,apparent_temperature,relative_humidity_2m,'
              'weather_code,wind_speed_10m',
        },
      ),
    ).called(1);
  });
}
