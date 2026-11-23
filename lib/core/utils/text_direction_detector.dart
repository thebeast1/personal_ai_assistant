import 'package:material_ui/material_ui.dart';

/// Picks a text direction from the first letter that has a strong direction,
/// the way browsers handle `dir="auto"`. Digits, spaces, punctuation, emoji
/// and markdown symbols (`**`, `#`, `-`) are skipped.
///
/// Returns null when the text has no such letter yet (empty, only numbers, or
/// a streamed reply whose first token is still markdown), so the caller can
/// fall back to the app's direction.
TextDirection? detectTextDirection(String text) {
  for (final rune in text.runes) {
    if (_isRtl(rune)) return TextDirection.rtl;
    if (_isLtrLetter(rune)) return TextDirection.ltr;
  }
  return null;
}

/// Hebrew, Arabic, Syriac, Thaana, N'Ko and their presentation forms.
bool _isRtl(int c) =>
    (c >= 0x0590 && c <= 0x08FF) ||
    (c >= 0xFB1D && c <= 0xFDFF) ||
    (c >= 0xFE70 && c <= 0xFEFF) ||
    (c >= 0x10800 && c <= 0x10FFF) ||
    (c >= 0x1E800 && c <= 0x1EFFF);

/// Latin, Greek, Cyrillic and other left-to-right scripts. Digits and
/// symbols are below 0x41 or in the excluded ranges, so they never match.
bool _isLtrLetter(int c) =>
    (c >= 0x41 && c <= 0x5A) ||
    (c >= 0x61 && c <= 0x7A) ||
    (c >= 0x00C0 && c <= 0x058F && c != 0x00D7 && c != 0x00F7) ||
    (c >= 0x0900 && c <= 0x1FFF) ||
    (c >= 0x2C00 && c <= 0x2DFF) ||
    (c >= 0x3040 && c <= 0x9FFF) ||
    (c >= 0xAC00 && c <= 0xD7AF);
