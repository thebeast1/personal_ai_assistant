import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_ai_assistant/core/network/error/app_exceptions.dart';
import 'package:personal_ai_assistant/core/network/error/failure.dart';
import 'package:personal_ai_assistant/features/location/data/data_sources/location_data_source.dart';
import 'package:personal_ai_assistant/features/location/data/models/location_model.dart';
import 'package:personal_ai_assistant/features/location/data/repositories/location_repository_impl.dart';

class _MockLocationDataSource extends Mock implements LocationDataSource {}

void main() {
  const giza = LocationModel(
    latitude: 30.1,
    longitude: 31.2,
    name: 'Giza',
    country: 'Egypt',
  );

  late _MockLocationDataSource dataSource;
  late LocationRepositoryImpl repository;

  setUp(() {
    dataSource = _MockLocationDataSource();
    repository = LocationRepositoryImpl(locationDataSource: dataSource);
  });

  test('returns the current location', () async {
    when(() => dataSource.getCurrentLocation()).thenAnswer((_) async => giza);

    final result = await repository.getCurrentLocation();

    expect(result.getOrElse(() => throw 'expected Right'), same(giza));
  });

  Future<Failure> failureFor(Object error) async {
    when(() => dataSource.getCurrentLocation()).thenThrow(error);
    final result = await repository.getCurrentLocation();
    return result.fold((f) => f, (_) => throw 'expected Left');
  }

  test('permission denied becomes LocationFailure', () async {
    expect(
      await failureFor(const LocationPermissionDeniedException()),
      isA<LocationFailure>(),
    );
  });

  test('location unavailable becomes LocationFailure', () async {
    expect(
      await failureFor(const LocationUnavailableException()),
      isA<LocationFailure>(),
    );
  });
}
