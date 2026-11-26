import '../../../core/network/error/failure.dart';

/// Short reason codes Gemma gets when a weather tool fails. Shared by
/// `get_weather` and `get_local_weather` so both speak the same language.
String weatherFailureCode(Failure failure) => switch (failure) {
  NotFoundFailure() => 'city_not_found',
  NetworkFailure() => 'no_internet',
  _ => 'service_unavailable',
};
