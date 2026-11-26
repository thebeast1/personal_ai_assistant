/// The languages the app supports.
enum AppLanguage {
  en('english'),
  ar('arabic');

  const AppLanguage(this._englishName);

  final String _englishName;

  /// Language code, as saved and as `Locale(code)`.
  String get code => name;

  /// Accepts a code or an English name in any case ("ar", "Arabic"), since
  /// the model doesn't always send the exact code. Unknown → `null`.
  static AppLanguage? parse(String? value) {
    final v = value?.trim().toLowerCase();
    for (final language in values) {
      if (v == language.code || v == language._englishName) return language;
    }
    return null;
  }
}
