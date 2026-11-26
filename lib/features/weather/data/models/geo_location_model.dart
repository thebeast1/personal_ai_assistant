class GeoLocationModel {
  final String name;
  final String country;
  final double latitude;
  final double longitude;

  const GeoLocationModel({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  factory GeoLocationModel.fromJson(Map<String, dynamic> json) =>
      GeoLocationModel(
        name: json['name'] ?? '',
        country: json['country'] ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );
}
