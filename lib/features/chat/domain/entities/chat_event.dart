import '../../../../core/tools/tool_result.dart';

/// What the chat receives while Gemma answers one message.
sealed class ChatEvent {
  const ChatEvent();
}

/// A streamed piece of the reply text.
final class TextChunk extends ChatEvent {
  const TextChunk(this.text);

  final String text;
}

/// A tool ran because Gemma asked for it. Comes before the text that uses
/// its result.
final class ToolExecuted extends ChatEvent {
  const ToolExecuted(this.toolName, this.result);

  final String toolName;
  final ToolResult result;
}
