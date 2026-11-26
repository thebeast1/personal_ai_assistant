import 'dart:async';

import 'package:flutter_edge_ai/flutter_edge_ai.dart';

import '../../../../core/tools/tool_registry.dart';
import '../../domain/entities/chat_event.dart';

typedef ToolCallHandler =
    Future<Map<String, dynamic>> Function(FunctionCallResponse call);

/// Turns flutter_edge_ai's tool-calling stream into [ChatEvent]s.
///
/// [generate] starts the SDK loop with the `onToolCall` handler given to it
/// (in the app: `chat.generateChatResponseWithTools(onToolCall: h)`). Kept
/// apart from the data source so it can be tested without loading Gemma.
Stream<ChatEvent> runToolLoop({
  required Stream<ModelResponse> Function(ToolCallHandler onToolCall) generate,
  required ToolRegistry registry,
}) {
  final controller = StreamController<ChatEvent>();

  Future<Map<String, dynamic>> onToolCall(FunctionCallResponse call) async {
    final result = await registry.dispatch(call);
    controller.add(ToolExecuted(call.name, result));
    return result.toModelResponse();
  }

  controller.onListen = () {
    generate(onToolCall).listen(
      (response) {
        if (response is TextResponse && response.token.isNotEmpty) {
          controller.add(TextChunk(response.token));
        }
      },
      onError: controller.addError,
      onDone: controller.close,
    );
  };

  return controller.stream;
}
