import 'dart:async';
import 'dart:developer';

import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:material_ui/material_ui.dart';
import 'package:personal_ai_assistant/core/services/injection.dart';
import 'package:personal_ai_assistant/core/tools/tool_result.dart';
import 'package:personal_ai_assistant/core/use_cases/use_cases.dart';
import 'package:personal_ai_assistant/features/chat/domain/entities/chat_entry.dart';
import 'package:personal_ai_assistant/features/chat/domain/entities/chat_event.dart';
import 'package:personal_ai_assistant/features/chat/domain/params/init_chat_params.dart';
import 'package:personal_ai_assistant/features/chat/domain/use_cases/clear_chat_use_case.dart';
import 'package:personal_ai_assistant/features/chat/domain/use_cases/init_chat_use_case.dart';
import 'package:personal_ai_assistant/features/chat/domain/use_cases/send_message_use_case.dart';

class ChatProvider extends ChangeNotifier {
  /// Use cases come from [sl] in the app. Tests pass mocks instead.
  ChatProvider({
    InitChatUseCase? initChatUseCase,
    SendMessageUseCase? sendMessageUseCase,
    ClearChatUseCase? clearChatUseCase,
  }) : _initChatUseCase = initChatUseCase ?? sl<InitChatUseCase>(),
       _sendMessageUseCase = sendMessageUseCase ?? sl<SendMessageUseCase>(),
       _clearChatUseCase = clearChatUseCase ?? sl<ClearChatUseCase>();

  final InitChatUseCase _initChatUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final ClearChatUseCase _clearChatUseCase;

  bool _disposed = false;

  int get installProgress => _installProgress;
  int _installProgress = 0;

  bool get isInitializing => _isInitializing;
  bool _isInitializing = true;

  bool get isGeneratingRespond => _isGeneratingRespond;
  bool _isGeneratingRespond = false;

  bool get isClearing => _isClearing;
  bool _isClearing = false;

  final _chatList = <ChatEntry>[];

  List<ChatEntry> get chatList => _chatList;

  Future<void> init() async {
    final result = await _initChatUseCase(
      InitChatParams(
        onProgress: (p) {
          _installProgress = p;
          notifyListeners();
        },
      ),
    );
    result.fold((failure) => log('error in init: ${failure.message}'), (_) {
      _isInitializing = false;
      notifyListeners();
    });
  }

  /// The reply being streamed, token by token. Empty until the first token.
  final StringBuffer draftMessage = StringBuffer();

  Future<void> send(Message userMessage) async {
    _chatList.add(MessageEntry(userMessage));
    draftMessage.clear();
    _isGeneratingRespond = true;
    notifyListeners();

    try {
      // Awaited so `finally` runs only after the last event has arrived.
      await for (final event in _sendMessageUseCase(userMessage)) {
        switch (event) {
          case TextChunk(:final text):
            draftMessage.write(text);
          case ToolExecuted(:final toolName, result: ToolSuccess(:final data)):
            _chatList.add(ToolResultEntry(toolName, data));
          case ToolExecuted():
            // A failed tool shows no card: Gemma explains it in the reply.
            break;
        }
        notifyListeners();
      }
    } catch (e) {
      log("Error in send: $e");
    } finally {
      _finishGenerationHandler();
    }
  }

  /// Moves the streamed draft into the chat list and ends generation.
  void _finishGenerationHandler() {
    if (draftMessage.isNotEmpty) {
      _chatList.add(
        MessageEntry(Message(text: draftMessage.toString(), isUser: false)),
      );
      draftMessage.clear();
    }
    _isGeneratingRespond = false;
    notifyListeners();
  }

  Future<void> clear() async {
    if (_isClearing || isGeneratingRespond) return;

    _isClearing = true;
    notifyListeners();

    final result = await _clearChatUseCase(const NoParams());
    result.fold((failure) => log("Error in clear: ${failure.message}"), (_) {
      _chatList.clear();
      draftMessage.clear();
    });

    _isClearing = false;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
