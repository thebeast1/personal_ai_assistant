import 'package:flutter_edge_ai/flutter_edge_ai.dart';

import 'tool_result.dart';

/// The contract every tool implements. A tool lives in its own feature
/// (`features/<name>/tool/`) and turns the model's arguments into a use case
/// call, then the use case's result into a [ToolResult].
abstract class AppTool {
  /// Name, description and JSON schema that Gemma reads to decide when and
  /// how to call this tool. The description matters: be specific.
  Tool get definition;

  String get name => definition.name;

  Future<ToolResult> execute(Map<String, dynamic> args);
}
