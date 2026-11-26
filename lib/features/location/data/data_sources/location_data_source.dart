import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/error/app_exceptions.dart';
import '../models/location_model.dart';

abstract class LocationDataSource {
  /// Asks for permission only when it hasn't been decided yet, so the system
  /// prompt appears the first time a tool needs the location.
  Future<LocationModel> getCurrentLocation();
}

@Injectable(as: LocationDataSource)
class LocationDataSourceImpl implements LocationDataSource {
  /// Weather needs the city, not the street: low accuracy is faster and more
  /// private.
  static const _kSettings = LocationSettings(
    accuracy: LocationAccuracy.low,
    timeLimit: Duration(seconds: 5),
  );

  @override
  Future<LocationModel> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationUnavailableException('Location services are off');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationPermissionDeniedException();
    }

    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: _kSettings,
      );
    } on TimeoutException {
      throw const LocationUnavailableException('Timed out');
    }

    final (name, country) = await placeNameFrom(
      () => Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ),
    );
    return LocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      name: name,
      country: country,
    );
  }
}

/// Turns the phone geocoder's answer into `(name, country)`.
///
/// Reverse geocoding is a nice-to-have and sits on the reply's path, so it
/// gets a [timeout]: on a slow or silent geocoder, an error or no result, the
/// coordinates are still used, with no name.
@visibleForTesting
Future<(String, String)> placeNameFrom(
  Future<List<Placemark>> Function() lookup, {
  Duration timeout = const Duration(seconds: 3),
}) async {
  try {
    final placemarks = await lookup().timeout(timeout);
    if (placemarks.isEmpty) return ('', '');
    final place = placemarks.first;
    final name = [
      place.locality,
      place.subAdministrativeArea,
      place.administrativeArea,
    ].firstWhere((s) => s != null && s.isNotEmpty, orElse: () => '');
    return (name ?? '', place.country ?? '');
  } catch (_) {
    return ('', '');
  }
}
