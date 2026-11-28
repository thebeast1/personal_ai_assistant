# Copy and share messages: design (small change)

Date: 2026-11-26
Status: approved

## Intent

Let the user copy a message, or share it to any other app, from a small
Copy / Share row under each message. Sharing works the same way as in
mismar-mobile-app.

## Behaviour

- **Where the row appears:** under every finished message that has text,
  both the user's and Khadeja's. The row sits on the bubble's side: end for
  the user, start for Khadeja (lined up with her bubble, past the avatar).
- **Where it doesn't:** not on the reply while it streams, not on photo-only
  or voice-only messages, and not on tool cards.
- **Copy:** copies to the clipboard. The icon turns into a ✓ for 2 s and a
  "Copied" snackbar appears, in English or Arabic.
- **Share:** opens the system share sheet with the text
  (`SharePlus.instance.share(ShareParams(text:))`, as in mismar).
- **What gets copied:** Khadeja's replies have their basic markdown removed
  first (`**`, `__`, `#` headings, backticks, code fences, `>` quotes,
  `[text](url)` → `text (url)`, `*`/`-` bullets → `•`). The user's own
  messages are copied exactly as typed.

## Approaches

1. **An action row under the bubble (chosen).** Visible and one tap away,
   like most chat apps.
2. **Long-press menu.** Hidden, and it clashes with the selectable text the
   bubbles already have.

## Design

- `share_plus` package.
- `lib/core/utils/app_util.dart`: `abstract final class AppUtil` with
  `copy(String)`, `share(String)` and `plainText(String markdown)` (mismar's
  `AppUtil` style).
- `lib/features/chat/presentation/widgets/message_actions.dart`:
  `MessageActions({required String text, required bool isUser, ShareCallback? onShare})`.
  `onShare` defaults to `AppUtil.share`; tests pass a fake.
- `MessageBubble` gets `showActions` (default `true`). The streaming draft
  passes `false`.
- `AppStrings`: `copy`, `copied`, `share`.

## Testing

- `AppUtil.plainText`: one case for each markdown form above, and plain
  text left unchanged.
- `MessageActions`: copy puts the plain text on the clipboard (assistant)
  or the raw text (user), the ✓ shows and then resets, and share receives
  the text.
- `MessageBubble`: actions show for a text message and are hidden with
  `showActions: false` or with no text.
