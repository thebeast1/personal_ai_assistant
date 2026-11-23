import 'package:material_ui/material_ui.dart';
import 'package:personal_ai_assistant/core/localization/app_strings.dart';

class LoadingWidget extends StatelessWidget {
  const new({super.key, required this.percent});

  final int percent;

  String _status(AppStrings strings) => switch (percent) {
    <= 0 => strings.preparingDownload,
    >= 100 => strings.finishingUp,
    _ => strings.downloadingModel,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    final target = (percent.clamp(0, 100)) / 100;
    final strings = AppStrings.of(context);
    final status = _status(strings);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: target),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ProgressRing(value: value, colors: colors, text: text),
                  const SizedBox(height: 32),
                  Text(
                    'Gemma 4',
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      status,
                      key: ValueKey(status),
                      style: text.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: colors.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FeatureChip(
                        icon: Icons.wifi_off_rounded,
                        label: strings.worksOffline,
                      ),
                      _FeatureChip(
                        icon: Icons.lock_outline_rounded,
                        label: strings.private,
                      ),
                      _FeatureChip(
                        icon: Icons.bolt_rounded,
                        label: strings.onDevice,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    strings.oneTimeDownload,
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.value,
    required this.colors,
    required this.text,
  });

  final double value;
  final ColorScheme colors;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    const size = 184.0;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft glow behind the ring.
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colors.primaryContainer,
                  colors.primaryContainer.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          SizedBox.square(
            dimension: size - 24,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 10,
              strokeCap: StrokeCap.round,
              backgroundColor: colors.surfaceContainerHighest,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, color: colors.primary, size: 22),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${(value * 100).round()}'),
                    TextSpan(
                      text: '%',
                      style: text.titleMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                style: text.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Icon(icon, size: 16, color: colors.onSecondaryContainer),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
