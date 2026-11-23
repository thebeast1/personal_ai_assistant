import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:personal_ai_assistant/core/localization/app_strings.dart';

/// Thumbnail of the image attached to the message being written, shown above
/// the input field. Tap to view it full screen; the corner button removes it.
/// Renders nothing (and animates in/out) when [image] is null.
class AttachmentChip extends StatelessWidget {
  const new({super.key, this.image, this.onDelete});

  final Uint8List? image;
  final Function()? onDelete;

  static const _size = 76.0;

  @override
  Widget build(BuildContext context) {
      final image = this.image;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: AlignmentDirectional.bottomStart,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: image == null
            ? const SizedBox(width: double.infinity)
            : Align(
                key: ValueKey(image),
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 4,
                    bottom: 8,
                  ),
                  child: _Thumbnail(image: image, onDelete: onDelete),
                ),
              ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.image, this.onDelete});

  final Uint8List image;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strings = AppStrings.of(context);
    const size = AttachmentChip._size;

    return SizedBox.square(
      // Extra room so the remove button can overlap the corner.
      dimension: size + 8,
      child: Stack(
        children: [
          PositionedDirectional(
            start: 0,
            bottom: 0,
            child: Material(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openPreview(context),
                child: Ink.image(
                  image: MemoryImage(image),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          if (onDelete != null)
            PositionedDirectional(
              top: 0,
              end: 0,
              child: Tooltip(
                message: strings.removeImage,
                child: Material(
                  color: colors.inverseSurface,
                  shape: CircleBorder(
                    side: BorderSide(color: colors.surface, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onDelete,
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: colors.onInverseSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openPreview(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 4,
                child: Center(child: Image.memory(image)),
              ),
            ),
            PositionedDirectional(
              top: 8,
              end: 8,
              child: SafeArea(
                child: IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
