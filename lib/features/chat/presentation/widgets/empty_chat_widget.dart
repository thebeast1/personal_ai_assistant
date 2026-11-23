import 'package:material_ui/material_ui.dart';
import 'package:personal_ai_assistant/core/localization/app_strings.dart';

/// Shown when the conversation is empty: a short greeting and up to
/// [maxSuggestions] prompts the user can tap to send right away.
class EmptyChatWidget extends StatelessWidget {
  const new({super.key, required this.onSuggest});

  /// Called with the tapped suggestion's text.
  final Function(String) onSuggest;

  static const maxSuggestions = 5;

  /// Suggestions in the current app language, at most [maxSuggestions].
  static List<Suggestion> suggestionsList(AppStrings strings) => [
    Suggestion(Icons.auto_awesome_rounded, strings.suggestWhatCanYouDo),
    Suggestion(Icons.lightbulb_outline_rounded, strings.suggestExplain),
    Suggestion(Icons.edit_note_rounded, strings.suggestWrite),
    Suggestion(Icons.fitness_center_rounded, strings.suggestWorkout),
    Suggestion(Icons.restaurant_rounded, strings.suggestDinner),
  ].take(maxSuggestions).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    final strings = AppStrings.of(context);
    final suggestions = suggestionsList(strings);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 30,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.emptyChatTitle,
                textAlign: TextAlign.center,
                style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                strings.emptyChatSubtitle,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              for (final suggestion in suggestions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SuggestionTile(
                    suggestion: suggestion,
                    onTap: () => onSuggest(suggestion.text),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One tappable prompt: an icon and the text that gets sent.
class Suggestion {
  const Suggestion(this.icon, this.text);

  final IconData icon;
  final String text;
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.suggestion, required this.onTap});

  final Suggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Material(
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            spacing: 12,
            children: [
              Icon(suggestion.icon, size: 20, color: colors.primary),
              Expanded(
                child: Text(
                  suggestion.text,
                  style: text.bodyMedium?.copyWith(color: colors.onSurface),
                ),
              ),
              // Mirrored in Arabic so it points toward the end of the line.
              Transform.flip(
                flipX: Directionality.of(context) == TextDirection.rtl,
                child: Icon(
                  Icons.north_east_rounded,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
