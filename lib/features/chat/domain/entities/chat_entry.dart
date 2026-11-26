import 'package:flutter_edge_ai/flutter_edge_ai.dart';

/// One item in the chat list.
sealed class ChatEntry {
  const ChatEntry();
}

/// A user or assistant message. Wraps flutter_edge_ai's [Message] on purpose:
/// the bubbles already render its text, images and audio.
final class MessageEntry extends ChatEntry {
  const MessageEntry(this.message);

  final Message message;
}

/// The card for a tool that succeeded, for example the weather card.
final class ToolResultEntry extends ChatEntry {
  const ToolResultEntry(this.toolName, this.data);

  final String toolName;
  final Map<String, dynamic> data;
}
