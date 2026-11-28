import 'dart:ui';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/enums/app_language.dart';
import '../../domain/enums/app_theme_mode.dart';

abstract class AppSettingsLocalDataSource {
  AppSettings read();

  /// The language the app shows when none is saved: the first supported one
  /// in the phone's list, else English (how Flutter picks it too).
  AppLanguage deviceLanguage();

  Future<void> saveLanguage(AppLanguage language);

  Future<void> saveThemeMode(AppThemeMode mode);
}

@LazySingleton(as: AppSettingsLocalDataSource)
class AppSettingsLocalDataSourceImpl implements AppSettingsLocalDataSource {
  AppSettingsLocalDataSourceImpl(
    this._prefs, {
    @ignoreParam List<Locale> Function()? deviceLocales,
  }) : _deviceLocales =
           deviceLocales ?? (() => PlatformDispatcher.instance.locales);

  /// The key the old language setting used, so a saved language carries over.
  static const languageKey = 'app_language';
  static const themeModeKey = 'theme_mode';

  final SharedPreferencesWithCache _prefs;
  final List<Locale> Function() _deviceLocales;

  @override
  AppSettings read() => AppSettings(
    language: AppLanguage.parse(_prefs.getString(languageKey)),
    themeMode:
        AppThemeMode.parse(_prefs.getString(themeModeKey)) ??
        AppThemeMode.system,
  );

  @override
  AppLanguage deviceLanguage() {
    for (final locale in _deviceLocales()) {
      final language = AppLanguage.parse(locale.languageCode);
      if (language != null) return language;
    }
    return AppLanguage.en;
  }

  @override
  Future<void> saveLanguage(AppLanguage language) =>
      _prefs.setString(languageKey, language.code);

  @override
  Future<void> saveThemeMode(AppThemeMode mode) =>
      _prefs.setString(themeModeKey, mode.name);
}
