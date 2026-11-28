import 'package:flutter_test/flutter_test.dart';
import 'package:personal_ai_assistant/core/utils/app_util.dart';

void main() {
  group('AppUtil.plainText', () {
    test('plain text is unchanged', () {
      expect(AppUtil.plainText('Hello, how are you?'), 'Hello, how are you?');
    });

    test('removes bold and italic markers', () {
      expect(
        AppUtil.plainText('It is **sunny** and __warm__ today'),
        'It is sunny and warm today',
      );
    });

    test('removes heading marks', () {
      expect(AppUtil.plainText('## Packing list\nShoes'), 'Packing list\nShoes');
    });

    test('removes inline code backticks and code fences', () {
      expect(
        AppUtil.plainText('Run `flutter run`:\n```bash\nflutter run\n```'),
        'Run flutter run:\nflutter run',
      );
    });

    test('removes quote marks', () {
      expect(AppUtil.plainText('> Be kind'), 'Be kind');
    });

    test('turns links into text plus url', () {
      expect(
        AppUtil.plainText('See [Open-Meteo](https://open-meteo.com)'),
        'See Open-Meteo (https://open-meteo.com)',
      );
    });

    test('turns * and - bullets into •', () {
      expect(
        AppUtil.plainText('* Water\n- Snacks\n  * Fruit'),
        '• Water\n• Snacks\n  • Fruit',
      );
    });
  });
}
