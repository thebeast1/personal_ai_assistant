import 'package:material_ui/material_ui.dart';
import 'package:personal_ai_assistant/core/localization/app_strings.dart';

/// Shown above the input field for a voice message:
/// - while recording: a pulsing red dot, the elapsed time against the limit
///   and a progress bar that fills up to the limit;
/// - after recording ([hasAudio]): the recorded clip's length and a delete
///   button.
/// Takes no space (and animates in/out) when neither applies.
class RecordingPreview extends StatelessWidget {
  const RecordingPreview({
    super.key,
    required this.isRecording,
    required this.duration,
    required this.maxDuration,
    this.hasAudio = false,
    this.onDelete,
  });

  final bool isRecording;
  final Duration duration;
  final Duration maxDuration;
  final bool hasAudio;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final visible = isRecording || hasAudio;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: AlignmentDirectional.bottomStart,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: !visible
            ? const SizedBox(width: double.infinity)
            : Padding(
                key: ValueKey(isRecording),
                padding: const EdgeInsets.only(bottom: 8),
                child: isRecording
                    ? _RecordingCard(duration: duration, maxDuration: maxDuration)
                    : _RecordedCard(duration: duration, onDelete: onDelete),
              ),
      ),
    );
  }
}

class _RecordingCard extends StatelessWidget {
  const _RecordingCard({required this.duration, required this.maxDuration});

  final Duration duration;
  final Duration maxDuration;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final strings = AppStrings.of(context);
    final progress = maxDuration.inMilliseconds == 0
        ? 0.0
        : (duration.inMilliseconds / maxDuration.inMilliseconds).clamp(0.0, 1.0);
    // Last 10 seconds before the limit: the time turns red as a warning.
    final nearLimit = maxDuration - duration <= const Duration(seconds: 10);

    return _Card(
      color: colors.errorContainer.withValues(alpha: 0.35),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          Row(
            spacing: 10,
            children: [
              _PulsingDot(color: colors.error),
              Expanded(
                child: Text(
                  strings.recording,
                  style: text.labelLarge?.copyWith(color: colors.onSurface),
                ),
              ),
              _TimeText(
                '${_format(duration)} / ${_format(maxDuration)}',
                style: text.labelLarge?.copyWith(
                  color: nearLimit ? colors.error : colors.onSurfaceVariant,
                  fontWeight: nearLimit ? FontWeight.w700 : null,
                ),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: progress),
              duration: const Duration(milliseconds: 900),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 4,
                color: colors.error,
                backgroundColor: colors.error.withValues(alpha: 0.15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordedCard extends StatelessWidget {
  const _RecordedCard({required this.duration, this.onDelete});

  final Duration duration;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final strings = AppStrings.of(context);

    return _Card(
      color: colors.secondaryContainer.withValues(alpha: 0.6),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 4, 4, 4),
      child: Row(
        spacing: 10,
        children: [
          Icon(Icons.graphic_eq_rounded, color: colors.onSecondaryContainer),
          Expanded(
            child: Text(
              strings.voiceMessage,
              style: text.labelLarge?.copyWith(
                color: colors.onSecondaryContainer,
              ),
            ),
          ),
          _TimeText(
            _format(duration),
            style: text.labelLarge?.copyWith(
              color: colors.onSecondaryContainer,
            ),
          ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              tooltip: strings.deleteRecording,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: colors.onSecondaryContainer,
              ),
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.color,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  final Color color;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

/// Time is always laid out left-to-right so "00:12 / 01:00" doesn't get
/// reordered in the Arabic UI. Tabular figures keep the width steady as the
/// seconds tick.
class _TimeText extends StatelessWidget {
  const _TimeText(this.value, {this.style});

  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textDirection: TextDirection.ltr,
      style: style?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_controller),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

String _format(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
