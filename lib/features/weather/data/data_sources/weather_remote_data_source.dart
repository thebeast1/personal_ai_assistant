import 'package:injectable/injectable.dart';

import '../../../../core/network/error/app_exceptions.dart';
import '../../../../core/network/web_service/api_endpoints.dart';
import '../../../../core/network/web_service/network_helper.dart';
import '../../domain/params/get_weather_params.dart';
import '../models/geo_location_model.dart';
import '../models/weather_model.dart';

abstract class WeatherRemoteDataSource {
  Future<GeoLocationModel> searchCity({required GetWeatherParams params});

  Future<WeatherModel> getCurrentWeather({required GeoLocationModel place});
}

@Injectable(as: WeatherRemoteDataSource)
class WeatherRemoteDataSourceImpl implements WeatherRemoteDataSource {
  WeatherRemoteDataSourceImpl({required this.networkHelper});

  final NetworkHelper networkHelper;

  static const _kCurrentFields =
      'temperature_2m,apparent_temperature,relative_humidity_2m,'
      'weather_code,wind_speed_10m';

  @override
  Future<GeoLocationModel> searchCity({
    required GetWeatherParams params,
  }) async {
    final response = await networkHelper.get(
      url: ApiEndpoints.openMeteoGeocoding,
      queryParams: params.toJson(),
    );
    // Open-Meteo leaves out `results` entirely when nothing matches.
    final results = response['results'] as List?;
    if (results == null || results.isEmpty) {
      throw NotFoundException('No city called "${params.city}" was found.');
    }
    return GeoLocationModel.fromJson(results.first);
  }

  @override
  Future<WeatherModel> getCurrentWeather({
    required GeoLocationModel place,
  }) async {
    final response = await networkHelper.get(
      url: ApiEndpoints.openMeteoForecast,
      queryParams: {
        'latitude': place.latitude,
        'longitude': place.longitude,
        'current': _kCurrentFields,
      },
    );
    return WeatherModel.fromApiJson(response['current'], place: place);
  }
}
