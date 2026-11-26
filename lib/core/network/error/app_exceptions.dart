/// Thrown by a data source when the request worked but found nothing,
/// for example a city name the geocoding API doesn't know.
class NotFoundException implements Exception {
  const NotFoundException(this.message);

  final String message;

  @override
  String toString() => 'NotFoundException: $message';
}
