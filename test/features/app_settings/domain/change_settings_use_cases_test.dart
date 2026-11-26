import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_ai_assistant/core/network/error/failure.dart';
import 'package:personal_ai_assistant/features/app_settings/domain/enums/app_language.dart';
import 'package:personal_ai_assistant/features/app_settings/domain/enums/app_theme_mode.dart';
import 'package:personal_ai_assistant/features/app_settings/domain/repositories/app_settings_repository.dart';
import 'package:personal_ai_assistant/features/app_settings/domain/use_cases/change_language_use_case.dart';
import 'package:personal_ai_assistant/features/app_settings/domain/use_cases/change_theme_mode_use_case.dart';

class _MockRepository extends Mock implements AppSettingsRepository {}

void main() {
  late _MockRepository repository;

  setUp(() => repository = _MockRepository());

  test('ChangeLanguageUseCase forwards to the repository', () async {
    when(() => repository.setLanguage(AppLanguage.ar))
        .thenAnswer((_) async => const Right(true));

    final result = await ChangeLanguageUseCase(
      appSettingsRepository: repository,
    )(AppLanguage.ar);

    expect(result, const Right<Failure, bool>(true));
  });

  test('ChangeThemeModeUseCase forwards to the repository', () async {
    when(() => repository.setThemeMode(AppThemeMode.dark))
        .thenAnswer((_) async => const Right(false));

    final result = await ChangeThemeModeUseCase(
      appSettingsRepository: repository,
    )(AppThemeMode.dark);

    expect(result, const Right<Failure, bool>(false));
  });
}
