import 'package:flutter_edge_ai/engine.dart';
import 'package:material_ui/material_ui.dart';
import 'package:personal_ai_assistant/core/services/injection.dart';
import 'package:personal_ai_assistant/core/tools/tool_result_views.dart';
import 'package:personal_ai_assistant/features/chat/domain/entities/chat_entry.dart';
import 'package:personal_ai_assistant/features/chat/presentation/provider/chat_provider.dart';
import 'package:personal_ai_assistant/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:personal_ai_assistant/features/chat/presentation/widgets/empty_chat_widget.dart';
import 'package:personal_ai_assistant/features/chat/presentation/widgets/message_bubble.dart';
import 'package:personal_ai_assistant/features/chat/presentation/widgets/message_skeleton.dart';
import 'package:provider/provider.dart';

class ChatWidget extends StatelessWidget {
  const ChatWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [_ChatListWidget(), ChatInputBar()]);
  }
}

class _ChatListWidget extends StatelessWidget {
  const _ChatListWidget();

  @override
  Widget build(BuildContext context) {
    return Selector<ChatProvider, (List<ChatEntry>, int, bool)>(
      selector: (_, p) =>
          (p.chatList, p.chatList.length, p.isGeneratingRespond),
      builder: (context, data, _) {
        final (entries, length, isGenerating) = data;
        final chatList = entries.reversed.toList();
        // The list is reversed, so index 0 is the bottom: the reply being
        // generated sits there, below the latest message.
        final offset = isGenerating ? 1 : 0;
        // Shown outside the list: with no messages its itemCount is 0, so
        // an item builder would never run.
        if (chatList.isEmpty && !isGenerating) {
          return Expanded(
            child: EmptyChatWidget(
              onSuggest: (text) {
                context.read<ChatProvider>().send(
                  Message.text(text: text, isUser: true),
                );
              },
            ),
          );
        }
        return Expanded(
          child: ListView.builder(
            reverse: true,
            itemCount: length + offset,
            itemBuilder: (context, index) {
              if (isGenerating && index == 0) return const _DraftReply();
              return switch (chatList[index - offset]) {
                MessageEntry(:final message) => MessageBubble(message: message),
                ToolResultEntry(:final toolName, :final data) =>
                  _ToolResultCard(toolName: toolName, data: data),
              };
            },
          ),
        );
      },
    );
  }
}

/// The reply being generated: a skeleton until the first token arrives, then
/// the streamed text. Selects only the draft, so each token rebuilds this
/// item alone instead of the whole list.
class _DraftReply extends StatelessWidget {
  const _DraftReply();

  @override
  Widget build(BuildContext context) {
    final draft = context.select<ChatProvider, String>(
      (p) => p.draftMessage.toString(),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: draft.isEmpty
          ? const MessageSkeleton(key: ValueKey('skeleton'))
          : MessageBubble(
              key: const ValueKey('draft'),
              message: Message(text: draft, isUser: false),
            ),
    );
  }
}

/// The card a tool registered for its result, start-aligned like the
/// assistant's bubbles. Nothing when the tool has no card.
class _ToolResultCard extends StatelessWidget {
  const _ToolResultCard({required this.toolName, required this.data});

  final String toolName;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final card = sl<ToolResultViews>().build(context, toolName, data);
    if (card == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(52, 4, 12, 4),
      child: Align(alignment: AlignmentDirectional.centerStart, child: card),
    );
  }
}
