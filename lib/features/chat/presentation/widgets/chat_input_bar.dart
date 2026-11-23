import 'dart:developer';

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:personal_ai_assistant/core/localization/app_strings.dart';
import 'package:personal_ai_assistant/features/chat/presentation/provider/chat_composer_provider.dart';
import 'package:personal_ai_assistant/features/chat/presentation/provider/chat_provider.dart';
import 'package:personal_ai_assistant/features/chat/presentation/widgets/attachment_chip.dart';
import 'package:personal_ai_assistant/features/chat/presentation/widgets/recording_preview.dart';
import 'package:personal_ai_assistant/features/chat/presentation/widgets/sheets/image_picker_sheet.dart';
import 'package:provider/provider.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ChatComposerProvider(),
      builder: (context, child) {
        return _ChatInputBarContent();
      },
    );
  }
}

class _ChatInputBarContent extends StatelessWidget {
  const _ChatInputBarContent();

  Future<void> _send(BuildContext context) async {
    final chatProvider = context.read<ChatProvider>();
    final chatComposerProvider = context.read<ChatComposerProvider>();

    final message = chatComposerProvider.takeMessage();
    if (message != null) chatProvider.send(message);
  }

  Future<bool> ensureCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) await openAppSettings();
    return status.isGranted;
  }

  Future<void> _pickImages(BuildContext context) async {
    final source = await ImagePickerSheet.pick(context);
    if (source == null) return;
    final picker = ImagePicker();

    try {
      if (source == ImageSource.camera) {
        final isGranted = await ensureCameraPermission();
        if (!isGranted) return;

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Camera Permission is required!")),
        );
      }
      final file = await picker.pickImage(
        source: source,
        maxHeight: 1024,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (file == null) return;
      // ignore: use_build_context_synchronously
      final chatComposerProvider = context.read<ChatComposerProvider>();
      chatComposerProvider.updateImage(file);
    } catch (e) {
      log("error in _pickImages:$e");
    }
  }


  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strings = AppStrings.of(context);
    return Consumer2<ChatComposerProvider, ChatProvider>(
      builder: (_, composerProvider, chatProvider, _) {
        final enabled =
            composerProvider.canSend && !chatProvider.isGeneratingRespond;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Column(
              children: [
                AttachmentChip(
                  image: composerProvider.imageBytes,
                  onDelete: () {
                    composerProvider.clearImage();
                  },
                ),
                RecordingPreview(
                  isRecording: composerProvider.isRecording,
                  duration: composerProvider.duration,
                  maxDuration: ChatComposerProvider.maximumDurationRecording,
                  hasAudio: composerProvider.audioBytes != null,
                  onDelete: composerProvider.clearAudio,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: 8,
                  children: [
                    AnimatedScale(
                      scale: enabled ? 1 : 0.9,
                      duration: const Duration(milliseconds: 150),
                      child: IconButton(
                        onPressed: !chatProvider.isGeneratingRespond
                            ? () {
                                _pickImages(context);
                              }
                            : null,
                        iconSize: 22,
                        style: IconButton.styleFrom(
                          fixedSize: const Size.square(50),
                        ),
                        tooltip: strings.send,
                        icon: const Icon(Icons.attach_file),
                      ),
                    ),

                    Expanded(
                      child: TextField(
                        enabled: !chatProvider.isGeneratingRespond,
                        controller: composerProvider.textController,
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) {
                          _send(context);
                        },
                        decoration: InputDecoration(
                          hintText: strings.messageHint,
                          filled: true,
                          fillColor: colors.surfaceContainerHigh,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              composerProvider.toggleRecording(context);
                            },
                            tooltip: composerProvider.isRecording
                                ? strings.stopRecording
                                : strings.startRecording,
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) =>
                                  ScaleTransition(scale: animation, child: child),
                              child: composerProvider.isRecording
                                  ? Icon(
                                      Icons.stop_circle_rounded,
                                      key: const ValueKey('stop'),
                                      color: colors.error,
                                    )
                                  : const Icon(
                                      Icons.mic,
                                      key: ValueKey('mic'),
                                    ),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    AnimatedScale(
                      scale: enabled ? 1 : 0.9,
                      duration: const Duration(milliseconds: 150),
                      child: IconButton.filled(
                        onPressed: enabled
                            ? () {
                                _send(context);
                              }
                            : null,
                        iconSize: 22,
                        style: IconButton.styleFrom(
                          fixedSize: const Size.square(50),
                        ),
                        tooltip: strings.send,
                        icon: const Icon(Icons.arrow_upward_rounded),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
