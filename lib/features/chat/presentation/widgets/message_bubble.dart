import 'dart:typed_data';

import 'package:flutter_edge_ai/engine.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:personal_ai_assistant/core/localization/app_strings.dart';
import 'package:personal_ai_assistant/core/utils/text_direction_detector.dart';
import 'package:personal_ai_assistant/core/utils/wav_info.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});
  final Message message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final colors = Theme.of(context).colorScheme;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;

    const radius = Radius.circular(20);
    const tail = Radius.circular(6);

    final bubble = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isUser ? colors.primary : colors.surfaceContainerHigh,
          // Directional so the tail corner flips with right-to-left (Arabic).
          borderRadius: BorderRadiusDirectional.only(
            topStart: radius,
            topEnd: radius,
            bottomStart: isUser ? radius : tail,
            bottomEnd: isUser ? tail : radius,
          ),
        ),
        // The text follows its own language (an Arabic reply reads
        // right-to-left in the English UI and vice versa), while the bubble's
        // side and tail corner, resolved above, follow the app language.
        child: Directionality(
          textDirection:
              detectTextDirection(message.text) ?? Directionality.of(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _BubbleContent(message: message),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 8,
        children: [
          if (!isUser) const AssistantAvatar(),
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

class _BubbleContent extends StatelessWidget {
  const _BubbleContent({required this.message});
  final Message message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textColor = message.isUser
        ? colors.onPrimary
        : colors.onSurface;

    final images = [?message.imageBytes, ...message.images];
    final text = message.text.trim();

    // Assistant reply that hasn't streamed any text yet.
    if (!message.isUser && text.isEmpty && images.isEmpty && !message.hasAudio) {
      return _TypingIndicator(color: colors.onSurfaceVariant);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        for (final bytes in images)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(bytes, fit: BoxFit.cover),
          ),
        if (message.hasAudio)
          _VoiceMessageRow(audio: message.audioBytes!, color: textColor),
        if (text.isNotEmpty)
          if (message.isUser)
            SelectableText(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: textColor,
                height: 1.4,
              ),
            )
          else
            MarkdownBody(
              data: text,
              selectable: true,
              styleSheet: _markdownStyle(context, textColor),
            ),
      ],
    );
  }
}

/// "🎤 Voice message · 00:12" row with a waveform drawn from the clip itself.
class _VoiceMessageRow extends StatelessWidget {
  const _VoiceMessageRow({required this.audio, required this.color});

  final Uint8List audio;
  final Color color;

  static const _bars = 28;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final text = Theme.of(context).textTheme;
    final wav = WavInfo.parse(audio);
    final levels = wav?.waveform(_bars) ?? List.filled(_bars, 0.3);
    final duration = wav?.duration;

    return Semantics(
      label: duration == null
          ? strings.voiceMessage
          : '${strings.voiceMessage}, ${_formatDuration(duration)}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.mic_rounded, size: 20, color: color),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                SizedBox(
                  height: 22,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 2,
                    children: [
                      for (final level in levels)
                        Container(
                          width: 3,
                          height: 4 + 18 * level,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    Text(
                      strings.voiceMessage,
                      style: text.labelMedium?.copyWith(
                        color: color.withValues(alpha: 0.85),
                      ),
                    ),
                    if (duration != null)
                      Text(
                        _formatDuration(duration),
                        // Keeps "00:12" left-to-right in the Arabic UI.
                        textDirection: TextDirection.ltr,
                        style: text.labelMedium?.copyWith(
                          color: color.withValues(alpha: 0.85),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// Built from the app theme's colors and text styles directly, so the
/// markdown matches the bubble in light and dark mode.
MarkdownStyleSheet _markdownStyle(BuildContext context, Color textColor) {
  final colors = Theme.of(context).colorScheme;
  final text = Theme.of(context).textTheme;
  final body = text.bodyLarge?.copyWith(color: textColor, height: 1.4);
  final code = body?.copyWith(
    fontFamily: 'monospace',
    fontSize: (body.fontSize ?? 16) * 0.9,
    backgroundColor: colors.surfaceContainerHighest,
  );

  return MarkdownStyleSheet(
    p: body,
    pPadding: EdgeInsets.zero,
    a: body?.copyWith(
      color: colors.primary,
      decoration: TextDecoration.underline,
    ),
    strong: const TextStyle(fontWeight: FontWeight.w700),
    em: const TextStyle(fontStyle: FontStyle.italic),
    del: const TextStyle(decoration: TextDecoration.lineThrough),
    h1: text.titleLarge?.copyWith(color: textColor, fontWeight: FontWeight.w700),
    h2: text.titleMedium?.copyWith(color: textColor, fontWeight: FontWeight.w700),
    h3: text.titleSmall?.copyWith(color: textColor, fontWeight: FontWeight.w700),
    h4: body?.copyWith(fontWeight: FontWeight.w700),
    h5: body?.copyWith(fontWeight: FontWeight.w700),
    h6: body?.copyWith(fontWeight: FontWeight.w700),
    h1Padding: const EdgeInsets.only(top: 4),
    h2Padding: const EdgeInsets.only(top: 4),
    h3Padding: const EdgeInsets.only(top: 4),
    blockSpacing: 10,
    listIndent: 22,
    listBullet: body,
    listBulletPadding: const EdgeInsets.only(right: 4),
    code: code,
    codeblockPadding: const EdgeInsets.all(12),
    codeblockDecoration: BoxDecoration(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    blockquote: body?.copyWith(color: colors.onSurfaceVariant),
    blockquotePadding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
    blockquoteDecoration: BoxDecoration(
      border: Border(left: BorderSide(color: colors.primary, width: 3)),
    ),
    tableHead: body?.copyWith(fontWeight: FontWeight.w700),
    tableBody: body,
    tableBorder: TableBorder.all(color: colors.outlineVariant, width: 1),
    tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(top: BorderSide(color: colors.outlineVariant)),
    ),
  );
}

class AssistantAvatar extends StatelessWidget {
  const AssistantAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 16,
      backgroundColor: colors.primaryContainer,
      child: Icon(
        Icons.auto_awesome_rounded,
        size: 18,
        color: colors.onPrimaryContainer,
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.color});
  final Color color;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: List.generate(3, (i) {
            // Each dot pulses a little after the previous one.
            final t = (_controller.value - i * 0.2) % 1.0;
            final pulse = t < 0.5 ? t * 2 : (1 - t) * 2;
            return Opacity(
              opacity: 0.35 + 0.65 * pulse,
              child: Transform.translate(
                offset: Offset(0, -3 * pulse),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
