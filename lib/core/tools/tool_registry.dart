import 'package:flutter_edge_ai/flutter_edge_ai.dart';

import 'app_tool.dart';
import 'tool_result.dart';

/// The toolbox: holds every [AppTool], gives the chat their definitions and
/// routes each call from the model to the right tool.
///
/// [dispatch] never throws. flutter_edge_ai rethrows any exception from a
/// tool on the reply stream, so every error becomes a [ToolFailure] the
/// model can explain instead.
class ToolRegistry {
  ToolRegistry(List<AppTool> tools)
    : _tools = {for (final tool in tools) tool.name: tool} {
    if (_tools.length != tools.length) {
      throw ArgumentError.value(
        tools.map((t) => t.name).toList(),
        'tools',
        'Tool names must be unique',
      );
    }
  }

  final Map<String, AppTool> _tools;

  List<Tool> get definitions =>
      _tools.values.map((tool) => tool.definition).toList();

  Future<ToolResult> dispatch(FunctionCallResponse call) async {
    final tool = _tools[call.name];
    if (tool == null) {
      return ToolFailure(
        code: 'unknown_tool',
        message: 'There is no tool called "${call.name}".',
      );
    }
    try {
      return await tool.execute(call.args);
    } catch (e) {
      return ToolFailure(code: 'tool_error', message: e.toString());
    }
  }
}
