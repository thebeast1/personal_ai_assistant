import 'package:material_ui/material_ui.dart';
import 'package:personal_ai_assistant/core/localization/app_strings.dart';
import 'package:personal_ai_assistant/core/localization/locale_provider.dart';
import 'package:personal_ai_assistant/features/chat/presentation/provider/chat_provider.dart';
import 'package:personal_ai_assistant/features/chat/presentation/widgets/chat_widget.dart';
import 'package:personal_ai_assistant/features/chat/presentation/widgets/loading_widget.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.assistantName),
        centerTitle: true,
        leading: const _ClearChatButton(),
        actions: const [_LanguageButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: Selector<ChatProvider, (bool, int)>(
          selector: (_, p) => (p.isInitializing, p.installProgress),
          builder: (context, data, _) {
            final (loading, percent) = data;
            if (loading) return LoadingWidget(percent: percent);
            return ChatWidget();
          },
        ),
      ),
    );
  }
}

/// Switches the app between English and Arabic. Shows the name of the
/// language it switches to, written in that language.
class _LanguageButton extends StatelessWidget {
  const _LanguageButton();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Tooltip(
      message: strings.switchLanguageTooltip,
      child: TextButton.icon(
        onPressed: () => context.read<LocaleProvider>().toggle(
          Localizations.localeOf(context),
        ),
        icon: const Icon(Icons.translate_rounded, size: 20),
        label: Text(strings.switchLanguage),
      ),
    );
  }
}

/// Clears the conversation after the user confirms. Disabled while there's
/// nothing to clear, the model is loading or replying, or a clear is running.
class _ClearChatButton extends StatelessWidget {
  const _ClearChatButton();

  Future<void> _confirmAndClear(BuildContext context) async {
    final provider = context.read<ChatProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _ClearChatDialog(),
    );
    if (confirmed ?? false) await provider.clear();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final canClear = context.select<ChatProvider, bool>(
      (p) =>
          p.chatList.isNotEmpty &&
          !p.isInitializing &&
          !p.isGeneratingRespond &&
          !p.isClearing,
    );

    return IconButton(
      onPressed: canClear ? () => _confirmAndClear(context) : null,
      tooltip: strings.clearChat,
      icon: const Icon(Icons.delete_outline_rounded),
    );
  }
}

class _ClearChatDialog extends StatelessWidget {
  const _ClearChatDialog();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strings = AppStrings.of(context);

    return AlertDialog(
      icon: Icon(Icons.delete_outline_rounded, color: colors.error),
      title: Text(strings.clearChatTitle),
      content: Text(strings.clearChatMessage, textAlign: TextAlign.center),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(strings.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: colors.onError,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(strings.clear),
        ),
      ],
    );
  }
}
