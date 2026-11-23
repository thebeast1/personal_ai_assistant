import 'package:material_ui/material_ui.dart';
import 'package:personal_ai_assistant/core/localization/app_strings.dart';
import 'package:personal_ai_assistant/features/chat/presentation/widgets/message_bubble.dart';

/// Placeholder assistant bubble with shimmering lines, shown while the model
/// is generating a reply.
class MessageSkeleton extends StatefulWidget {
  const MessageSkeleton({super.key});

  @override
  State<MessageSkeleton> createState() => _MessageSkeletonState();
}

class _MessageSkeletonState extends State<MessageSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;
    final base = colors.onSurface.withValues(alpha: 0.08);
    final highlight = colors.onSurface.withValues(alpha: 0.18);

    return Semantics(
      label: AppStrings.of(context).assistantTyping,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 8,
          children: [
            const AssistantAvatar(),
            Flexible(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: const BorderRadiusDirectional.only(
                    topStart: Radius.circular(20),
                    topEnd: Radius.circular(20),
                    bottomStart: Radius.circular(6),
                    bottomEnd: Radius.circular(20),
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => ShaderMask(
                    blendMode: BlendMode.srcATop,
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [base, highlight, base],
                      stops: const [0.35, 0.5, 0.65],
                      transform: _SlideGradient(_controller.value),
                    ).createShader(
                      bounds,
                      textDirection: Directionality.of(context),
                    ),
                    child: child,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      _line(base, maxWidth * 0.62),
                      _line(base, maxWidth * 0.52),
                      _line(base, maxWidth * 0.34),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(Color color, double width) => Container(
    width: width,
    height: 12,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

/// Moves the shimmer highlight across the bubble in reading direction.
class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.progress);
  final double progress;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(
        bounds.width *
            (progress * 2 - 1) *
            (textDirection == TextDirection.rtl ? -1 : 1),
        0,
        0,
      );
}
