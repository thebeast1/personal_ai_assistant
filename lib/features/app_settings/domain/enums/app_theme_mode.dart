/// Light, dark, or follow the phone's setting.
enum AppThemeMode {
  light,
  dark,
  system;

  /// Case-insensitive name ("Dark" → [dark]). Unknown → `null`.
  static AppThemeMode? parse(String? value) {
    final v = value?.trim().toLowerCase();
    for (final mode in values) {
      if (v == mode.name) return mode;
    }
    return null;
  }
}
