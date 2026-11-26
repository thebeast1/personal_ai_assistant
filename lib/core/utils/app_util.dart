import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

abstract final class AppUtil {
  static Future<void> copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  /// Opens the system share sheet. [origin] is where the sheet points from on
  /// iPad (required there); phones ignore it.
  static Future<void> share(String text, {Rect? origin}) =>
      SharePlus.instance.share(
        ShareParams(text: text, sharePositionOrigin: origin),
      );

  /// Strips basic markdown so a shared reply reads cleanly in other apps,
  /// where `**bold**` or `# heading` would show as raw symbols.
  static String plainText(String markdown) {
    final lines = <String>[];
    for (final line in markdown.split('\n')) {
      if (line.trimLeft().startsWith('```')) continue; // code fences
      lines.add(
        line
            .replaceFirst(RegExp(r'^\s{0,3}#{1,6}\s+'), '') // headings
            .replaceFirst(RegExp(r'^\s*>\s?'), '') // quotes
            .replaceFirstMapped(
              RegExp(r'^(\s*)[*-]\s+'), // bullets
              (m) => '${m[1]}• ',
            ),
      );
    }
    return lines
        .join('\n')
        .replaceAllMapped(
          RegExp(r'\[([^\]]+)\]\(([^)]+)\)'), // links
          (m) => '${m[1]} (${m[2]})',
        )
        .replaceAll(RegExp(r'\*\*|__'), '') // bold
        .replaceAll('`', '') // inline code
        .trim();
  }
}
