import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_ai_assistant/core/tools/app_tool.dart';
import 'package:personal_ai_assistant/core/tools/tool_registry.dart';
import 'package:personal_ai_assistant/core/tools/tool_result.dart';

class _EchoTool extends AppTool {
  @override
  Tool get definition => const Tool(name: 'echo', description: 'Echoes args');

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async =>
      ToolSuccess(args);
}

class _ThrowingTool extends AppTool {
  @override
  Tool get definition => const Tool(name: 'boom', description: 'Always throws');

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) =>
      throw StateError('boom');
}

void main() {
  group('ToolRegistry', () {
    test('definitions keep registration order', () {
      final registry = ToolRegistry([_EchoTool(), _ThrowingTool()]);
      expect(registry.definitions.map((t) => t.name), ['echo', 'boom']);
    });

    test('dispatch runs the tool with the matching name', () async {
      final registry = ToolRegistry([_EchoTool()]);
      final result = await registry.dispatch(
        const FunctionCallResponse(name: 'echo', args: {'x': 1}),
      );
      expect(result, isA<ToolSuccess>());
      expect((result as ToolSuccess).data, {'x': 1});
    });

    test('an unknown tool name returns unknown_tool', () async {
      final registry = ToolRegistry([_EchoTool()]);
      final result = await registry.dispatch(
        const FunctionCallResponse(name: 'nope', args: {}),
      );
      expect(result, isA<ToolFailure>());
      expect((result as ToolFailure).code, 'unknown_tool');
    });

    test('a tool that throws returns tool_error instead of throwing', () async {
      final registry = ToolRegistry([_ThrowingTool()]);
      final result = await registry.dispatch(
        const FunctionCallResponse(name: 'boom', args: {}),
      );
      expect(result, isA<ToolFailure>());
      expect((result as ToolFailure).code, 'tool_error');
    });

    test('two tools with the same name are rejected', () {
      expect(
        () => ToolRegistry([_EchoTool(), _EchoTool()]),
        throwsArgumentError,
      );
    });
  });
}
