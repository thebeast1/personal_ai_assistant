import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/enums/app_language.dart';
import '../../domain/enums/app_theme_mode.dart';

abstract class AppSettingsLocalDataSource {
  AppSettings read();

  Future<void> saveLanguage(AppLanguage language);

  Future<void> saveThemeMode(AppThemeMode mode);
}

@LazySingleton(as: AppSettingsLocalDataSource)
class AppSettingsLocalDataSourceImpl implements AppSettingsLocalDataSource {
  AppSettingsLocalDataSourceImpl(this._prefs);

  /// Same key `LocaleProvider` used, so a saved language carries over.
  static const languageKey = 'app_language';
  static const themeModeKey = 'theme_mode';

  final SharedPreferencesWithCache _prefs;

  @override
  AppSettings read() => AppSettings(
    language: AppLanguage.parse(_prefs.getString(languageKey)),
    themeMode:
        AppThemeMode.parse(_prefs.getString(themeModeKey)) ??
        AppThemeMode.system,
  );

  @override
  Future<void> saveLanguage(AppLanguage language) =>
      _prefs.setString(languageKey, language.code);

  @override
  Future<void> saveThemeMode(AppThemeMode mode) =>
      _prefs.setString(themeModeKey, mode.name);
}
