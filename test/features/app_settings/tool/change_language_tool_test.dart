import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_ai_assistant/core/network/error/failure.dart';
import 'package:personal_ai_assistant/core/tools/tool_result.dart';
import 'package:personal_ai_assistant/features/app_settings/domain/enums/app_language.dart';
import 'package:personal_ai_assistant/features/app_settings/domain/use_cases/change_language_use_case.dart';
import 'package:personal_ai_assistant/features/app_settings/tool/change_language_tool.dart';

class _MockChangeLanguage extends Mock implements ChangeLanguageUseCase {}

void main() {
  late _MockChangeLanguage useCase;
  late ChangeLanguageTool tool;

  setUpAll(() => registerFallbackValue(AppLanguage.en));

  setUp(() {
    useCase = _MockChangeLanguage();
    tool = ChangeLanguageTool(changeLanguageUseCase: useCase);
    when(() => useCase(any())).thenAnswer((_) async => const Right(true));
  });

  test('the definition requires language with en and ar', () {
    final params = tool.definition.parameters;
    expect(tool.name, 'change_language');
    expect(params['required'], ['language']);
    expect(params['properties']['language']['enum'], ['en', 'ar']);
  });

  test('switching returns the language and changed', () async {
    final result = await tool.execute({'language': 'ar'}) as ToolSuccess;

    expect(result.data, {'language': 'ar', 'changed': true});
    verify(() => useCase(AppLanguage.ar)).called(1);
  });

  test('already active returns changed false', () async {
    when(() => useCase(any())).thenAnswer((_) async => const Right(false));

    final result = await tool.execute({'language': 'en'}) as ToolSuccess;

    expect(result.data, {'language': 'en', 'changed': false});
  });

  test('accepts names and any case', () async {
    await tool.execute({'language': 'Arabic'});
    await tool.execute({'language': 'EN'});

    verify(() => useCase(AppLanguage.ar)).called(1);
    verify(() => useCase(AppLanguage.en)).called(1);
  });

  test('unknown or missing language fails', () async {
    for (final args in [
      {'language': 'fr'},
      <String, dynamic>{},
    ]) {
      final result = await tool.execute(args) as ToolFailure;
      expect(result.code, 'unsupported_language');
      expect(result.message, contains('(en)'));
      expect(result.message, contains('(ar)'));
    }
    verifyNever(() => useCase(any()));
  });

  test('a save failure fails', () async {
    when(() => useCase(any())).thenAnswer((_) async => Left(CacheFailure()));

    final result = await tool.execute({'language': 'ar'}) as ToolFailure;

    expect(result.code, 'settings_not_saved');
    expect(result.message, 'Could not save the setting.');
  });
}
