import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_ai_assistant/core/network/error/failure.dart';
import 'package:personal_ai_assistant/features/app_settings/data/data_sources/app_settings_local_data_source.dart';
import 'package:personal_ai_assistant/features/app_settings/data/repositories/app_settings_repository_impl.dart';
import 'package:personal_ai_assistant/features/app_settings/domain/entities/app_settings.dart';
import 'package:personal_ai_assistant/features/app_settings/domain/enums/app_language.dart';
import 'package:personal_ai_assistant/features/app_settings/domain/enums/app_theme_mode.dart';

class _MockDataSource extends Mock implements AppSettingsLocalDataSource {}

void main() {
  late _MockDataSource dataSource;
  late AppSettingsRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(AppLanguage.en);
    registerFallbackValue(AppThemeMode.system);
  });

  setUp(() {
    dataSource = _MockDataSource();
    when(() => dataSource.read())
        .thenReturn(const AppSettings(themeMode: AppThemeMode.dark));
    when(() => dataSource.saveLanguage(any())).thenAnswer((_) async {});
    when(() => dataSource.saveThemeMode(any())).thenAnswer((_) async {});
    repository = AppSettingsRepositoryImpl(dataSource);
  });

  test('current comes from the data source', () {
    expect(repository.current, const AppSettings(themeMode: AppThemeMode.dark));
  });

  test('setLanguage saves, updates current and emits', () async {
    const expected = AppSettings(
      language: AppLanguage.ar,
      themeMode: AppThemeMode.dark,
    );
    final emitted = expectLater(repository.changes, emits(expected));

    final result = await repository.setLanguage(AppLanguage.ar);

    expect(result, const Right<Failure, bool>(true));
    expect(repository.current, expected);
    verify(() => dataSource.saveLanguage(AppLanguage.ar)).called(1);
    await emitted;
  });

  test('setThemeMode saves, updates current and emits', () async {
    final emitted = expectLater(
      repository.changes,
      emits(const AppSettings(themeMode: AppThemeMode.light)),
    );

    final result = await repository.setThemeMode(AppThemeMode.light);

    expect(result, const Right<Failure, bool>(true));
    expect(repository.current.themeMode, AppThemeMode.light);
    await emitted;
  });

  test('setting the same value returns false and does not save', () async {
    final result = await repository.setThemeMode(AppThemeMode.dark);

    expect(result, const Right<Failure, bool>(false));
    verifyNever(() => dataSource.saveThemeMode(any()));
  });

  test('a save error returns CacheFailure and keeps current', () async {
    when(() => dataSource.saveThemeMode(any())).thenThrow(Exception('disk'));
    final emitted = <AppSettings>[];
    final sub = repository.changes.listen(emitted.add);

    final result = await repository.setThemeMode(AppThemeMode.light);
    await pumpEventQueue();

    expect(result.fold((f) => f, (_) => null), isA<CacheFailure>());
    expect(repository.current.themeMode, AppThemeMode.dark);
    expect(emitted, isEmpty);
    await sub.cancel();
  });
}
