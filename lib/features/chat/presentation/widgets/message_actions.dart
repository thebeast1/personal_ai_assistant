import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:personal_ai_assistant/core/localization/app_strings.dart';
import 'package:personal_ai_assistant/core/utils/app_util.dart';

typedef ShareCallback = Future<void> Function(String text, Rect? origin);

/// Copy and Share buttons under a message. Khadeja's replies are copied and
/// shared without markdown symbols; the user's own text is kept as typed.
class MessageActions extends StatefulWidget {
  const MessageActions({
    super.key,
    required this.text,
    required this.isUser,
    this.onShare,
  });

  final String text;
  final bool isUser;

  /// Defaults to the system share sheet. Tests pass a fake.
  final ShareCallback? onShare;

  @override
  State<MessageActions> createState() => _MessageActionsState();
}

class _MessageActionsState extends State<MessageActions> {
  bool _copied = false;
  Timer? _resetTimer;

  String get _content =>
      widget.isUser ? widget.text : AppUtil.plainText(widget.text);

  Future<void> _copy() async {
    final copied = AppStrings.of(context).copied;
    final messenger = ScaffoldMessenger.maybeOf(context);
    await AppUtil.copy(_content);
    if (!mounted) return;
    setState(() => _copied = true);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(copied), duration: const Duration(seconds: 2)),
      );
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _share(BuildContext buttonContext) {
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    final share =
        widget.onShare ??
        (String text, Rect? origin) => AppUtil.share(text, origin: origin);
    return share(_content, origin);
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    const iconSize = 16.0;
    const constraints = BoxConstraints.tightFor(width: 32, height: 32);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _copy,
          tooltip: strings.copy,
          constraints: constraints,
          padding: EdgeInsets.zero,
          iconSize: iconSize,
          color: color,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Icon(
              _copied ? Icons.check_rounded : Icons.copy_rounded,
              key: ValueKey(_copied),
            ),
          ),
        ),
        Builder(
          builder: (buttonContext) => IconButton(
            onPressed: () => _share(buttonContext),
            tooltip: strings.share,
            constraints: constraints,
            padding: EdgeInsets.zero,
            iconSize: iconSize,
            color: color,
            icon: const Icon(Icons.share_rounded),
          ),
        ),
      ],
    );
  }
}
