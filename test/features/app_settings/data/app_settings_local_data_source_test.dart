import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_ai_assistant/features/app_settings/data/data_sources/app_settings_local_data_source.dart';
import 'package:personal_ai_assistant/features/app_settings/domain/entities/app_settings.dart';
import 'package:personal_ai_assistant/features/app_settings/domain/enums/app_language.dart';
import 'package:personal_ai_assistant/features/app_settings/domain/enums/app_theme_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockPrefs extends Mock implements SharedPreferencesWithCache {}

void main() {
  late _MockPrefs prefs;
  late AppSettingsLocalDataSourceImpl dataSource;

  setUp(() {
    prefs = _MockPrefs();
    dataSource = AppSettingsLocalDataSourceImpl(prefs);
  });

  void saved({String? language, String? theme}) {
    when(() => prefs.getString('app_language')).thenReturn(language);
    when(() => prefs.getString('theme_mode')).thenReturn(theme);
  }

  test('nothing saved gives no language and the system theme', () {
    saved();
    expect(dataSource.read(), const AppSettings());
  });

  test('reads saved values', () {
    saved(language: 'ar', theme: 'dark');
    expect(
      dataSource.read(),
      const AppSettings(language: AppLanguage.ar, themeMode: AppThemeMode.dark),
    );
  });

  test('unknown saved values are treated as unset', () {
    saved(language: 'fr', theme: 'blue');
    expect(dataSource.read(), const AppSettings());
  });

  test('saves the language code and the theme name', () async {
    when(() => prefs.setString(any(), any())).thenAnswer((_) async {});

    await dataSource.saveLanguage(AppLanguage.ar);
    await dataSource.saveThemeMode(AppThemeMode.light);

    verify(() => prefs.setString('app_language', 'ar')).called(1);
    verify(() => prefs.setString('theme_mode', 'light')).called(1);
  });

  group('deviceLanguage', () {
    AppLanguage of(List<Locale> locales) => AppSettingsLocalDataSourceImpl(
      prefs,
      deviceLocales: () => locales,
    ).deviceLanguage();

    test('is the first supported language in the phone list', () {
      expect(of(const [Locale('fr'), Locale('ar', 'EG')]), AppLanguage.ar);
    });

    test('falls back to English', () {
      expect(of(const [Locale('fr')]), AppLanguage.en);
      expect(of(const []), AppLanguage.en);
    });
  });
}
