import 'package:flutter/services.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:personal_ai_assistant/features/chat/presentation/widgets/message_actions.dart';
import 'package:personal_ai_assistant/features/chat/presentation/widgets/message_bubble.dart';

Widget _app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  locale: locale,
  supportedLocales: const [Locale('en'), Locale('ar')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: Scaffold(body: child),
);

void main() {
  String? clipboard;

  setUp(() {
    clipboard = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String?;
          }
          return null;
        });
  });

  group('MessageActions', () {
    testWidgets('copy puts the plain text of a reply on the clipboard', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const MessageActions(text: 'It is **sunny**', isUser: false)),
      );

      await tester.tap(find.byTooltip('Copy'));
      await tester.pump();

      expect(clipboard, 'It is sunny');
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('Copied'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 200)); // icon fade
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets("the user's own message is copied as typed", (tester) async {
      await tester.pumpWidget(
        _app(const MessageActions(text: 'Use **this**', isUser: true)),
      );

      await tester.tap(find.byTooltip('Copy'));
      await tester.pump();

      expect(clipboard, 'Use **this**');
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('share sends the plain text to the share sheet', (
      tester,
    ) async {
      String? shared;
      await tester.pumpWidget(
        _app(
          MessageActions(
            text: '# Tip\nDrink water',
            isUser: false,
            onShare: (text, _) async => shared = text,
          ),
        ),
      );

      await tester.tap(find.byTooltip('Share'));
      await tester.pump();

      expect(shared, 'Tip\nDrink water');
    });

    testWidgets('labels are in Arabic in the Arabic UI', (tester) async {
      await tester.pumpWidget(
        _app(
          const MessageActions(text: 'مرحبا', isUser: true),
          locale: const Locale('ar'),
        ),
      );

      expect(find.byTooltip('نسخ'), findsOneWidget);
      expect(find.byTooltip('مشاركة'), findsOneWidget);
    });
  });

  group('MessageBubble actions', () {
    testWidgets('a finished text message shows copy and share', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(MessageBubble(message: Message(text: 'Hi', isUser: false))),
      );
      expect(find.byType(MessageActions), findsOneWidget);
    });

    testWidgets('hidden while streaming (showActions: false)', (tester) async {
      await tester.pumpWidget(
        _app(
          MessageBubble(
            message: Message(text: 'Hi', isUser: false),
            showActions: false,
          ),
        ),
      );
      expect(find.byType(MessageActions), findsNothing);
    });

    testWidgets('hidden when the message has no text', (tester) async {
      await tester.pumpWidget(
        _app(MessageBubble(message: Message(text: '   ', isUser: true))),
      );
      expect(find.byType(MessageActions), findsNothing);
    });
  });
}
