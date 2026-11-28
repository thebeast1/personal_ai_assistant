import 'package:flutter_edge_ai/engine.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/tools/tool_registry.dart';
import '../../../../core/utils/app_constants.dart';
import '../../domain/entities/chat_event.dart';
import 'tool_loop.dart';

abstract class ChatDataSource {
  Future<void> init({required void Function(int percent) onProgress});

  Stream<ChatEvent> send({required Message message});

  Future<void> reset();
}

/// The only class that talks to flutter_edge_ai's engine. A singleton: it
/// holds the loaded model and the open chat.
@LazySingleton(as: ChatDataSource)
class ChatDataSourceImpl implements ChatDataSource {
  ChatDataSourceImpl({required this.toolRegistry});

  final ToolRegistry toolRegistry;

  /// Safety cap on model ↔ tool round-trips for one reply.
  static const _kMaxToolTurns = 4;

  late InferenceModel _model;
  late InferenceChat _chat;

  @override
  Future<void> init({required void Function(int percent) onProgress}) async {
    await FlutterEdgeAi.installModel(
      modelType: ModelType.gemma4,
      fileType: ModelFileType.litertlm,
    )
        .fromNetwork(AppConstants.gemmaURL, foreground: true)
        .withProgress(onProgress)
        .install();

    _model = await FlutterEdgeAi.getActiveModel(
      supportImage: true,
      supportAudio: true,
      maxTokens: 4096, // context window: prompt + history + reply
    );
    _chat = await _openChat();
  }

  @override
  Stream<ChatEvent> send({required Message message}) async* {
    await _chat.addQuery(message);
    yield* runToolLoop(
      generate: (onToolCall) => _chat.generateChatResponseWithTools(
        onToolCall: onToolCall,
        maxToolTurns: _kMaxToolTurns,
      ),
      registry: toolRegistry,
    );
  }

  @override
  Future<void> reset() async {
    await _chat.close();
    _chat = await _openChat();
  }

  Future<InferenceChat> _openChat() {
    final tools = toolRegistry.definitions;
    return _model.openChat(
      supportImage: true,
      supportAudio: true,
      temperature: 1.0,
      topK: 64,
      topP: 0.95,
      maxOutputTokens: 1024, // limits the length of one reply
      modelType: ModelType.gemma4,
      systemInstruction: AppConstants.systemInstruction,
      tools: tools,
      supportsFunctionCalls: tools.isNotEmpty,
    );
  }
}
