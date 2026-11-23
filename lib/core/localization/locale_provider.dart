import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app language and remembers the user's choice across restarts.
/// `null` follows the device language (Arabic if the device is Arabic,
/// English otherwise) until the user picks one.
class LocaleProvider extends ChangeNotifier {
  LocaleProvider(this._prefs) {
    final saved = _prefs.getString(prefsKey);
    if (saved != null) _locale = Locale(saved);
  }

  static const english = Locale('en');
  static const arabic = Locale('ar');
  static const supportedLocales = [english, arabic];

  /// Shared-preferences key for the saved language code ('en' or 'ar').
  static const prefsKey = 'app_language';

  final SharedPreferencesWithCache _prefs;

  Locale? _locale;

  Locale? get locale => _locale;

  /// Switches between English and Arabic, starting from the language
  /// currently shown on screen, and saves the choice.
  Future<void> toggle(Locale current) async {
    final next = current.languageCode == 'ar' ? english : arabic;
    _locale = next;
    notifyListeners();
    await _prefs.setString(prefsKey, next.languageCode);
  }
}
