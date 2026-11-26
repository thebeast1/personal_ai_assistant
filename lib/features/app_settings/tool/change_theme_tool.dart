import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:injectable/injectable.dart';

import '../../../core/tools/app_tool.dart';
import '../../../core/tools/tool_result.dart';
import '../domain/enums/app_theme_mode.dart';
import '../domain/use_cases/change_theme_mode_use_case.dart';

/// Light, dark, or follow the phone. No card: Khadeja confirms in her reply.
@injectable
class ChangeThemeTool extends AppTool {
  ChangeThemeTool({required this.changeThemeModeUseCase});

  final ChangeThemeModeUseCase changeThemeModeUseCase;

  static const toolName = 'change_theme';

  @override
  Tool get definition => const Tool(
    name: toolName,
    description:
        "Switch the app between light mode, dark mode, or following the "
        "phone's setting (system).",
    parameters: {
      'type': 'object',
      'properties': {
        'mode': {
          'type': 'string',
          'enum': ['light', 'dark', 'system'],
          'description': "system follows the phone's setting.",
        },
      },
      'required': ['mode'],
    },
  );

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final mode = AppThemeMode.parse(args['mode']?.toString());
    if (mode == null) {
      return const ToolFailure(
        code: 'unsupported_theme',
        message: 'Only light, dark and system are supported.',
      );
    }
    final result = await changeThemeModeUseCase(mode);
    return result.fold(
      (failure) =>
          ToolFailure(code: 'settings_not_saved', message: failure.message),
      (changed) => ToolSuccess({'mode': mode.name, 'changed': changed}),
    );
  }
}
