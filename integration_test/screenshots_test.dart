// Takes the README screenshots on a real device or simulator, with the real
// model. Run with:
//
//   flutter drive -d <device> \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/screenshots_test.dart
//
// `flutter drive` uninstalls the app when it finishes, so every run downloads
// the model (~2.6 GB) first; the test waits up to 45 minutes for it.
// Optional: SAMPLE_PHOTO=/path/to/image.png (--dart-define) for the
// attachment screenshot.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:personal_ai_assistant/core/localization/app_strings.dart';
import 'package:personal_ai_assistant/core/localization/locale_provider.dart';
import 'package:personal_ai_assistant/features/chat/presentation/chat_screen.dart';
import 'package:personal_ai_assistant/features/chat/presentation/provider/chat_composer_provider.dart';
import 'package:personal_ai_assistant/features/chat/presentation/provider/chat_provider.dart';
import 'package:personal_ai_assistant/features/chat/presentation/widgets/loading_widget.dart';
import 'package:personal_ai_assistant/features/chat/presentation/widgets/message_skeleton.dart';
import 'package:personal_ai_assistant/main.dart' as app;
import 'package:provider/provider.dart';

const _samplePhoto = String.fromEnvironment('SAMPLE_PHOTO');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pump(const Duration(milliseconds: 600));
    await binding.takeScreenshot(name);
  }

  /// Pumps frames until [done] is true. Animations (shimmer, progress) never
  /// settle, so pumpAndSettle can't be used.
  Future<void> waitUntil(
    WidgetTester tester,
    bool Function() done, {
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final end = DateTime.now().add(timeout);
    while (!done()) {
      if (DateTime.now().isAfter(end)) fail('Timed out waiting');
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  testWidgets('README screenshots', (tester) async {
    // 1. Download screen, shown on its own at 62 % (the model is already
    //    installed, so the real first-run screen can't be reached).
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: LocaleProvider.english,
        supportedLocales: LocaleProvider.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
        home: Scaffold(
          appBar: AppBar(title: const Text('Khadeja'), centerTitle: true),
          body: const SafeArea(child: LoadingWidget(percent: 62)),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, '01_download');

    // 2. The real app.
    await app.main();
    await tester.pump();
    BuildContext screen() => tester.element(find.byType(ChatScreen));
    final chat = screen().read<ChatProvider>();
    await waitUntil(tester, () => !chat.isInitializing,
        timeout: const Duration(minutes: 45));
    await tester.pump(const Duration(seconds: 1));

    if (Localizations.localeOf(screen()).languageCode == 'ar') {
      await tester.tap(find.byTooltip('التبديل إلى الإنجليزية'));
      await tester.pump(const Duration(seconds: 1));
    }
    if (chat.chatList.isNotEmpty) {
      await chat.clear();
      await tester.pump(const Duration(seconds: 1));
    }
    await shot(tester, '02_empty_chat');

    // 3. Tap a suggestion: skeleton, then the streamed reply.
    await tester.tap(find.text('What can you do?'));
    await tester.pump(const Duration(milliseconds: 300));
    if (find.byType(MessageSkeleton).evaluate().isNotEmpty) {
      await shot(tester, '03_thinking');
    }
    await waitUntil(tester, () => !chat.isGeneratingRespond);
    await shot(tester, '04_reply');

    // 4. Clear-conversation dialog.
    await tester.tap(find.byTooltip('Clear conversation'));
    await tester.pump(const Duration(milliseconds: 500));
    await shot(tester, '05_clear_dialog');
    await tester.tap(find.text('Clear'));
    await waitUntil(tester, () => !chat.isClearing && chat.chatList.isEmpty);

    // 5. Composer with a photo and a recorded voice message attached.
    final composer = tester
        .element(find.byType(TextField))
        .read<ChatComposerProvider>();
    if (_samplePhoto.isNotEmpty && File(_samplePhoto).existsSync()) {
      await composer.updateImage(
        XFile.fromData(File(_samplePhoto).readAsBytesSync()),
      );
    }
    await composer.updateAudio(XFile.fromData(_sampleWav()));
    composer.duration = const Duration(seconds: 4);
    await tester.enterText(find.byType(TextField), 'What is in this photo?');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 500));
    await shot(tester, '06_attachments');
    composer
      ..clearImage()
      ..clearAudio()
      ..textController.clear();

    // 6. Arabic: right-to-left UI and an Arabic reply.
    await tester.tap(find.byTooltip(AppStrings.of(screen()).switchLanguageTooltip));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, '07_arabic_empty');
    await tester.tap(find.text('ماذا يمكنك أن تفعل؟'));
    await tester.pump(const Duration(milliseconds: 300));
    await waitUntil(tester, () => !chat.isGeneratingRespond);
    await shot(tester, '08_arabic_reply');

    // Leave the app in English with an empty chat.
    await chat.clear();
    await tester.tap(find.byTooltip(AppStrings.of(screen()).switchLanguageTooltip));
    await tester.pump(const Duration(seconds: 1));
  }, timeout: const Timeout(Duration(minutes: 75)));
}

/// 4 s, 16 kHz mono 16-bit WAV that swells and fades, for a nice waveform.
Uint8List _sampleWav() {
  const rate = 16000;
  const frames = rate * 4;
  final data = ByteData(44 + frames * 2);
  void tag(int o, String s) {
    for (var i = 0; i < 4; i++) {
      data.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  data.setUint32(4, 36 + frames * 2, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  data.setUint32(40, frames * 2, Endian.little);
  for (var i = 0; i < frames; i++) {
    final t = i / frames;
    final envelope = math.sin(t * math.pi) * (0.55 + 0.45 * math.sin(t * 23));
    final v = 28000 * envelope * math.sin(i / 6);
    data.setInt16(44 + i * 2, v.round(), Endian.little);
  }
  return data.buffer.asUint8List();
}
