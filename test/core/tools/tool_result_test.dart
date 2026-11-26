import 'package:flutter_test/flutter_test.dart';
import 'package:personal_ai_assistant/core/tools/tool_result.dart';

void main() {
  test('ToolSuccess sends its data to the model as is', () {
    expect(const ToolSuccess({'a': 1}).toModelResponse(), {'a': 1});
  });

  test('ToolFailure sends an error code and a message', () {
    expect(
      const ToolFailure(code: 'city_not_found', message: 'No city').toModelResponse(),
      {'error': 'city_not_found', 'message': 'No city'},
    );
  });
}
