import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_edge_ai/engine.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class ChatComposerProvider extends ChangeNotifier {
  ChatComposerProvider() {
    textController.addListener(() {
      notifyListeners();
    });
  }

  /// True when there is something to send: text, an image or a recording.
  bool get canSend =>
      textController.text.trim().isNotEmpty ||
      _imageBytes != null ||
      _audioBytes != null;
  final textController = TextEditingController();

  bool _disposed = false;

  bool get isRecording => _isRecording;
  bool _isRecording = false;

  Uint8List? get imageBytes => _imageBytes;
  Uint8List? _imageBytes;

  Uint8List? get audioBytes => _audioBytes;
  Uint8List? _audioBytes;

  Duration duration = Duration.zero;
  Timer? timer;

  static const maximumDurationRecording = Duration(seconds: 60);
  final audioRecorder = AudioRecorder();

  Future<void> toggleRecording(BuildContext context) async {
    if (_isRecording) {
      stopRecording();
    } else {
      startRecording(context);
    }
  }

  Future<void> startRecording(BuildContext context) async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Microphone Permission is required!")),
      );
      return;
    }

    // Each recording counts from zero, so the 60 s limit applies per clip.
    duration = Duration.zero;
    _isRecording = true;
    notifyListeners();

    await audioRecorder.start(
      RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: '${Directory.systemTemp.path}/chat_audio.wav',
    );

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      duration += const Duration(seconds: 1);
      notifyListeners();
      if (duration >= maximumDurationRecording) {
        stopRecording();
      }
    });
  }

  Future<void> stopRecording() async {
    timer?.cancel();

    try {
      final path = await audioRecorder.stop();
      if (path != null) {
        final file = File(path);
        _audioBytes = await file.readAsBytes();
        if (await file.exists()) await file.delete();
      }
    } catch (e) {
      log("Error in stopRecording: $e");
    } finally {
      _isRecording = false;
      notifyListeners();
    }
  }

  Future<void> updateImage(XFile image) async {
    _imageBytes = await image.readAsBytes();
    notifyListeners();
  }

  void clearImage() {
    _imageBytes = null;
    notifyListeners();
  }

  Future<void> updateAudio(XFile image) async {
    _audioBytes = await image.readAsBytes();
    notifyListeners();
  }

  void clearAudio() {
    _audioBytes = null;
    notifyListeners();
  }

  Message? takeMessage() {
    final text = textController.text.trim();
    final hasImage = imageBytes?.isNotEmpty ?? false;
    final hasAudio = audioBytes?.isNotEmpty ?? false;
    if (text.isEmpty && !hasImage && !hasAudio) return null;
    final message = Message(
      text: text,
      imageBytes: imageBytes,
      audioBytes: audioBytes,
      isUser: true,
    );
    _imageBytes = null;
    _audioBytes = null;
    textController.clear();
    // clear() doesn't notify when the field was already empty (audio- or
    // image-only message), so notify here to hide the previews.
    notifyListeners();
    return message;
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
    textController.dispose();
  }
}
