import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_ai_assistant/core/tools/app_tool.dart';
import 'package:personal_ai_assistant/core/tools/tool_registry.dart';
import 'package:personal_ai_assistant/core/tools/tool_result.dart';
import 'package:personal_ai_assistant/features/chat/data/data_sources/tool_loop.dart';
import 'package:personal_ai_assistant/features/chat/domain/entities/chat_event.dart';

class _EchoTool extends AppTool {
  @override
  Tool get definition => const Tool(name: 'echo', description: 'Echoes args');

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async =>
      ToolSuccess(args);
}

/// Plays a script the way flutter_edge_ai does: text is streamed, and a
/// [FunctionCallResponse] is answered through `onToolCall` before going on.
Stream<ModelResponse> Function(ToolCallHandler) _script(
  List<ModelResponse> steps, {
  Object? errorAtEnd,
  List<Map<String, dynamic>>? toolAnswers,
}) {
  return (onToolCall) async* {
    for (final step in steps) {
      if (step is FunctionCallResponse) {
        final answer = await onToolCall(step);
        toolAnswers?.add(answer);
      } else {
        yield step;
      }
    }
    if (errorAtEnd != null) throw errorAtEnd;
  };
}

void main() {
  final registry = ToolRegistry([_EchoTool()]);

  test('text only: each token becomes a TextChunk', () async {
    final events = await runToolLoop(
      generate: _script([TextResponse('Hi'), TextResponse(' there')]),
      registry: registry,
    ).toList();

    expect(events.map((e) => (e as TextChunk).text), ['Hi', ' there']);
  });

  test('text, tool call, text: events keep their order', () async {
    final answers = <Map<String, dynamic>>[];
    final events = await runToolLoop(
      generate: _script([
        TextResponse('Checking'),
        const FunctionCallResponse(name: 'echo', args: {'x': 1}),
        TextResponse('Done'),
      ], toolAnswers: answers),
      registry: registry,
    ).toList();

    expect(events, hasLength(3));
    expect((events[0] as TextChunk).text, 'Checking');
    final executed = events[1] as ToolExecuted;
    expect(executed.toolName, 'echo');
    expect((executed.result as ToolSuccess).data, {'x': 1});
    expect((events[2] as TextChunk).text, 'Done');
    expect(answers, [
      {'x': 1},
    ], reason: 'the model gets the tool result back');
  });

  test('an unknown tool is reported and the reply goes on', () async {
    final events = await runToolLoop(
      generate: _script([
        const FunctionCallResponse(name: 'nope', args: {}),
        TextResponse('Sorry'),
      ]),
      registry: registry,
    ).toList();

    final failure = (events[0] as ToolExecuted).result as ToolFailure;
    expect(failure.code, 'unknown_tool');
    expect((events[1] as TextChunk).text, 'Sorry');
  });

  test('an error from the model stream is forwarded after the text', () async {
    final events = <ChatEvent>[];
    Object? error;
    try {
      await for (final event in runToolLoop(
        generate: _script([TextResponse('Par')], errorAtEnd: StateError('x')),
        registry: registry,
      )) {
        events.add(event);
      }
    } catch (e) {
      error = e;
    }

    expect((events.single as TextChunk).text, 'Par');
    expect(error, isA<StateError>());
  });

  test('empty tokens are skipped', () async {
    final events = await runToolLoop(
      generate: _script([TextResponse(''), TextResponse('a')]),
      registry: registry,
    ).toList();

    expect(events, hasLength(1));
  });
}
