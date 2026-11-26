import 'dart:async';
import 'dart:developer';

import 'package:material_ui/material_ui.dart';

import '../../../../core/services/injection.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/enums/app_language.dart';
import '../../domain/enums/app_theme_mode.dart';
import '../../domain/repositories/app_settings_repository.dart';
import '../../domain/use_cases/change_language_use_case.dart';

/// Gives `MaterialApp` the language and theme. Follows the repository, so a
/// change from a tool or from the app bar button shows up right away.
class AppSettingsProvider extends ChangeNotifier {
  /// Dependencies come from [sl] in the app. Tests pass mocks instead.
  AppSettingsProvider({
    AppSettingsRepository? repository,
    ChangeLanguageUseCase? changeLanguageUseCase,
  }) : _changeLanguageUseCase =
           changeLanguageUseCase ?? sl<ChangeLanguageUseCase>() {
    final repo = repository ?? sl<AppSettingsRepository>();
    _settings = repo.current;
    _subscription = repo.changes.listen((settings) {
      _settings = settings;
      notifyListeners();
    });
  }

  static final supportedLocales = [
    for (final language in AppLanguage.values) Locale(language.code),
  ];

  final ChangeLanguageUseCase _changeLanguageUseCase;
  late final StreamSubscription<AppSettings> _subscription;
  late AppSettings _settings;

  /// `null` follows the phone's language.
  Locale? get locale {
    final language = _settings.language;
    return language == null ? null : Locale(language.code);
  }

  ThemeMode get themeMode => switch (_settings.themeMode) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.system => ThemeMode.system,
  };

  /// The app bar button: English ↔ Arabic, based on what's showing now.
  Future<void> toggleLanguage(Locale current) async {
    final next = current.languageCode == AppLanguage.ar.code
        ? AppLanguage.en
        : AppLanguage.ar;
    final result = await _changeLanguageUseCase(next);
    result.fold((failure) => log('toggleLanguage: ${failure.message}'), (_) {});
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
