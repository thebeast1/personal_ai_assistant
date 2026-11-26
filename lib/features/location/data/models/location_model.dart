class LocationModel {
  final double latitude;
  final double longitude;

  /// City or area from the phone's geocoder. Empty when it couldn't be found.
  final String name;
  final String country;

  const LocationModel({
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.country,
  });
}
