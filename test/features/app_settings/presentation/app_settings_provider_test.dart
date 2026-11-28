import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_ai_assistant/features/app_settings/domain/entities/app_settings.dart';
import 'package:personal_ai_assistant/features/app_settings/domain/enums/app_language.dart';
import 'package:personal_ai_assistant/features/app_settings/domain/enums/app_theme_mode.dart';
import 'package:personal_ai_assistant/features/app_settings/domain/repositories/app_settings_repository.dart';
import 'package:personal_ai_assistant/features/app_settings/domain/use_cases/change_language_use_case.dart';
import 'package:personal_ai_assistant/features/app_settings/presentation/provider/app_settings_provider.dart';

class _MockRepository extends Mock implements AppSettingsRepository {}

class _MockChangeLanguage extends Mock implements ChangeLanguageUseCase {}

void main() {
  late _MockRepository repository;
  late _MockChangeLanguage changeLanguage;
  late StreamController<AppSettings> changes;

  setUpAll(() => registerFallbackValue(AppLanguage.en));

  setUp(() {
    repository = _MockRepository();
    changeLanguage = _MockChangeLanguage();
    changes = StreamController<AppSettings>.broadcast();
    when(() => repository.changes).thenAnswer((_) => changes.stream);
    when(() => changeLanguage(any()))
        .thenAnswer((_) async => const Right(true));
  });

  tearDown(() => changes.close());

  AppSettingsProvider build(AppSettings current) {
    when(() => repository.current).thenReturn(current);
    return AppSettingsProvider(
      repository: repository,
      changeLanguageUseCase: changeLanguage,
    );
  }

  test('starts from the saved settings', () {
    final provider = build(
      const AppSettings(language: AppLanguage.ar, themeMode: AppThemeMode.dark),
    );

    expect(provider.locale, const Locale('ar'));
    expect(provider.themeMode, ThemeMode.dark);
  });

  test('no saved language gives a null locale', () {
    final provider = build(const AppSettings());

    expect(provider.locale, isNull);
    expect(provider.themeMode, ThemeMode.system);
  });

  test('updates and notifies when the repository emits', () async {
    final provider = build(const AppSettings());
    var notified = 0;
    provider.addListener(() => notified++);

    changes.add(const AppSettings(themeMode: AppThemeMode.light));
    await pumpEventQueue();

    expect(provider.themeMode, ThemeMode.light);
    expect(notified, 1);
  });

  test('toggleLanguage switches en to ar and ar to en', () async {
    final provider = build(const AppSettings());

    await provider.toggleLanguage(const Locale('en'));
    verify(() => changeLanguage(AppLanguage.ar)).called(1);

    await provider.toggleLanguage(const Locale('ar'));
    verify(() => changeLanguage(AppLanguage.en)).called(1);
  });

  test('supportedLocales lists English and Arabic', () {
    expect(AppSettingsProvider.supportedLocales, const [
      Locale('en'),
      Locale('ar'),
    ]);
  });
}
