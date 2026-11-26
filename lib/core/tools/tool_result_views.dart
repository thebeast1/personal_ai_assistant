import 'package:material_ui/material_ui.dart';

typedef ToolResultBuilder =
    Widget Function(BuildContext context, Map<String, dynamic> data);

/// Maps a tool name to the card shown in the chat when that tool succeeds.
/// Each feature registers its own builder, so the chat can show a weather
/// card without importing the weather feature.
class ToolResultViews {
  const ToolResultViews(this._builders);

  final Map<String, ToolResultBuilder> _builders;

  /// Returns null when the tool has no card.
  Widget? build(
    BuildContext context,
    String toolName,
    Map<String, dynamic> data,
  ) => _builders[toolName]?.call(context, data);
}
