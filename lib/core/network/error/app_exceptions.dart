/// Thrown by a data source when the request worked but found nothing,
/// for example a city name the geocoding API doesn't know.
class NotFoundException implements Exception {
  const NotFoundException(this.message);

  final String message;

  @override
  String toString() => 'NotFoundException: $message';
}

/// The user refused location permission (now or permanently).
class LocationPermissionDeniedException implements Exception {
  const LocationPermissionDeniedException([this.message = 'Permission denied']);

  final String message;

  @override
  String toString() => 'LocationPermissionDeniedException: $message';
}

/// Location services are off, or the position didn't arrive in time.
class LocationUnavailableException implements Exception {
  const LocationUnavailableException([this.message = 'Location unavailable']);

  final String message;

  @override
  String toString() => 'LocationUnavailableException: $message';
}
