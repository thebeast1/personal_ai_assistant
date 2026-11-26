import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_ai_assistant/core/network/error/failure.dart';
import 'package:personal_ai_assistant/core/tools/tool_result.dart';
import 'package:personal_ai_assistant/features/app_settings/domain/enums/app_theme_mode.dart';
import 'package:personal_ai_assistant/features/app_settings/domain/use_cases/change_theme_mode_use_case.dart';
import 'package:personal_ai_assistant/features/app_settings/tool/change_theme_tool.dart';

class _MockChangeTheme extends Mock implements ChangeThemeModeUseCase {}

void main() {
  late _MockChangeTheme useCase;
  late ChangeThemeTool tool;

  setUpAll(() => registerFallbackValue(AppThemeMode.system));

  setUp(() {
    useCase = _MockChangeTheme();
    tool = ChangeThemeTool(changeThemeModeUseCase: useCase);
    when(() => useCase(any())).thenAnswer((_) async => const Right(true));
  });

  test('the definition requires mode with light, dark and system', () {
    final params = tool.definition.parameters;
    expect(tool.name, 'change_theme');
    expect(params['required'], ['mode']);
    expect(params['properties']['mode']['enum'], ['light', 'dark', 'system']);
  });

  test('switching returns the mode and changed', () async {
    final result = await tool.execute({'mode': 'dark'}) as ToolSuccess;

    expect(result.data, {'mode': 'dark', 'changed': true});
    verify(() => useCase(AppThemeMode.dark)).called(1);
  });

  test('already active returns changed false', () async {
    when(() => useCase(any())).thenAnswer((_) async => const Right(false));

    final result = await tool.execute({'mode': 'system'}) as ToolSuccess;

    expect(result.data, {'mode': 'system', 'changed': false});
  });

  test('accepts any case', () async {
    await tool.execute({'mode': 'Dark'});

    verify(() => useCase(AppThemeMode.dark)).called(1);
  });

  test('unknown or missing mode fails', () async {
    for (final args in [
      {'mode': 'blue'},
      <String, dynamic>{},
    ]) {
      final result = await tool.execute(args) as ToolFailure;
      expect(result.code, 'unsupported_theme');
      expect(result.message, 'Only light, dark and system are supported.');
    }
    verifyNever(() => useCase(any()));
  });

  test('a save failure fails', () async {
    when(() => useCase(any())).thenAnswer((_) async => Left(CacheFailure()));

    final result = await tool.execute({'mode': 'light'}) as ToolFailure;

    expect(result.code, 'settings_not_saved');
    expect(result.message, 'Could not save the setting.');
  });
}
