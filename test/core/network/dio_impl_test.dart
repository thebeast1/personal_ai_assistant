import 'package:flutter_test/flutter_test.dart';
import 'package:personal_ai_assistant/core/network/web_service/dio_impl.dart';

void main() {
  test('DioImpl fails fast: 10 s connect and receive timeouts', () {
    final options = DioImpl().options;
    expect(options.connectTimeout, const Duration(seconds: 10));
    expect(options.receiveTimeout, const Duration(seconds: 10));
  });
}
