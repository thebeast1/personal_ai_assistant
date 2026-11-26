import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:personal_ai_assistant/features/location/data/data_sources/location_data_source.dart';

void main() {
  test('a geocoder that never answers gives up with no name', () async {
    final result = await placeNameFrom(
      () => Completer<List<Placemark>>().future,
      timeout: const Duration(milliseconds: 50),
    );
    expect(result, ('', ''));
  });

  test('a geocoder error gives no name', () async {
    final result = await placeNameFrom(() async => throw Exception('offline'));
    expect(result, ('', ''));
  });

  test('no placemarks gives no name', () async {
    expect(await placeNameFrom(() async => <Placemark>[]), ('', ''));
  });

  test('uses the first non-empty of locality, sub-area, area', () async {
    final result = await placeNameFrom(
      () async => [
        Placemark(
          locality: '',
          subAdministrativeArea: null,
          administrativeArea: 'Cairo Governorate',
          country: 'Egypt',
        ),
      ],
    );
    expect(result, ('Cairo Governorate', 'Egypt'));
  });
}
