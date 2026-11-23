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
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      ).fromNetwork(AppConstants.gemmaURL, foreground: true).withProgress((p) {
        _installProgress = p;
        notifyListeners();
      }).install();

      _model = await FlutterEdgeAi.getActiveModel(
        supportImage: true,
        supportAudio: true,
        maxTokens: 4096, // context window: prompt + history + reply
      );
      _chat = await _model.openChat(
        supportImage: true,
        supportAudio: true,
        temperature: 1.0,
        topK: 64,
        topP: 0.95,
        maxOutputTokens: 1024,
        // optional: limits the length of one reply
        modelType: ModelType.gemma4,
        systemInstruction: AppConstants.systemInstruction,
      );
      _isInitializing = false;
      notifyListeners();
    } catch (e) {
      log("error in init: $e");
    }
  }

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
      _chat = await _model.openChat(
        supportImage: true,
        supportAudio: true,
        temperature: 1.0,
        topK: 64,
        topP: 0.95,
        maxOutputTokens: 1024,
        // optional: limits the length of one reply
        modelType: ModelType.gemma4,
        systemInstruction: AppConstants.systemInstruction,
      );
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
