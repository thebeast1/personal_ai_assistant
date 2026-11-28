import '../enums/app_language.dart';
import '../enums/app_theme_mode.dart';

class AppSettings {
  const AppSettings({this.language, this.themeMode = AppThemeMode.system});

  /// `null` means the user never picked one: follow the phone's language.
  final AppLanguage? language;
  final AppThemeMode themeMode;

  AppSettings copyWith({AppLanguage? language, AppThemeMode? themeMode}) =>
      AppSettings(
        language: language ?? this.language,
        themeMode: themeMode ?? this.themeMode,
      );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.language == language &&
      other.themeMode == themeMode;

  @override
  int get hashCode => Object.hash(language, themeMode);

  @override
  String toString() => 'AppSettings($language, $themeMode)';
}
