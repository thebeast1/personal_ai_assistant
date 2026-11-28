import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:injectable/injectable.dart';

import '../../../core/tools/app_tool.dart';
import '../../../core/tools/tool_result.dart';
import '../domain/enums/app_language.dart';
import '../domain/use_cases/change_language_use_case.dart';

/// Switches the whole app between English and Arabic, like the app bar
/// button. No card: Khadeja confirms in her reply.
@injectable
class ChangeLanguageTool extends AppTool {
  ChangeLanguageTool({required this.changeLanguageUseCase});

  final ChangeLanguageUseCase changeLanguageUseCase;

  static const toolName = 'change_language';

  @override
  Tool get definition => const Tool(
    name: toolName,
    description:
        "Change the app's language. Use when the user asks to switch the app "
        'to English or Arabic.',
    parameters: {
      'type': 'object',
      'properties': {
        'language': {
          'type': 'string',
          'enum': ['en', 'ar'],
          'description': 'en for English, ar for Arabic.',
        },
      },
      'required': ['language'],
    },
  );

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final language = AppLanguage.parse(args['language']?.toString());
    if (language == null) {
      return const ToolFailure(
        code: 'unsupported_language',
        message: 'Only English (en) and Arabic (ar) are supported.',
      );
    }
    final result = await changeLanguageUseCase(language);
    return result.fold(
      (failure) =>
          ToolFailure(code: 'settings_not_saved', message: failure.message),
      (changed) => ToolSuccess({'language': language.code, 'changed': changed}),
    );
  }
}
