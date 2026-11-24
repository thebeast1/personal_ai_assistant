import 'dart:async';
import 'dart:developer';

import 'package:flutter_edge_ai/engine.dart';
import 'package:material_ui/material_ui.dart';
import 'package:personal_ai_assistant/core/utils/app_constants.dart';

class ChatProvider extends ChangeNotifier {
  bool _disposed = false;

  int get installProgress => _installProgress;
  int _installProgress = 0;

  bool get isInitializing => _isInitializing;
  bool _isInitializing = true;

  bool get isGeneratingRespond => _isGeneratingRespond;
  bool _isGeneratingRespond = false;

  bool get isClearing => _isClearing;
  bool _isClearing = false;

  late InferenceModel _model;
  late InferenceChat _chat;

  final _chatList = <Message>[];

  List<Message> get chatList => _chatList;

  Future<void> init() async {
    try {
      await FlutterEdgeAi.installModel(
        modelType: ModelType.qwen,
        fileType: ModelFileType.gguf,
      ).fromNetwork(AppConstants.modelURL, foreground: true).withProgress((p) {
        _installProgress = p;
        notifyListeners();
      }).install();

      // Text only, and a 2048-token context to fit phones with 4 GB of RAM.
      _model = await FlutterEdgeAi.getActiveModel(
        maxTokens: 2048, // context window: prompt + history + reply
      );
      _chat = await _openChat();
      _isInitializing = false;
      notifyListeners();
    } catch (e) {
      log("error in init: $e");
    }
  }

  // Qwen2.5's recommended sampling settings.
  Future<InferenceChat> _openChat() => _model.openChat(
    temperature: 0.7,
    topK: 20,
    topP: 0.8,
    maxOutputTokens: 512, // optional: limits the length of one reply
    modelType: ModelType.qwen,
    systemInstruction: AppConstants.systemInstruction,
  );

  /// The reply being streamed, token by token. Empty until the first token.
  final StringBuffer draftMessage = StringBuffer();

  Future<void> send(Message userMessage) async {
    _chatList.add(userMessage);
    draftMessage.clear();
    _isGeneratingRespond = true;
    notifyListeners();

    try {
      await _chat.addQuery(userMessage);
      // return the respond all at once.
      // final response = await _chat.generateChatResponse();
      // if (response is TextResponse && response.token.isNotEmpty) {
      //   _chatList.add(Message(text: response.token, isUser: false));
      //   notifyListeners();
      // }

      // Awaited so `finally` runs only after the last token has arrived.
      await for (final response in _chat.generateChatResponseAsync()) {
        if (response is TextResponse && response.token.isNotEmpty) {
          draftMessage.write(response.token);
          notifyListeners();
        }
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
      _chatList.add(Message(text: draftMessage.toString(), isUser: false));
      draftMessage.clear();
    }
    _isGeneratingRespond = false;
    notifyListeners();
  }

  Future<void> clear() async {
    if (_isClearing || isGeneratingRespond) return;

    _isClearing = true;
    notifyListeners();
    try {
      await _chat.close();
      _chat = await _openChat();
      _chatList.clear();
      draftMessage.clear();
    } catch (e) {
      log("Error in clear: $e");
    } finally {
      _isClearing = false;
      notifyListeners();
    }
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
