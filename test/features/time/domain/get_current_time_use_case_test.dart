import 'package:flutter_test/flutter_test.dart';
import 'package:personal_ai_assistant/core/use_cases/use_cases.dart';
import 'package:personal_ai_assistant/features/time/domain/use_cases/get_current_time_use_case.dart';

void main() {
  test('returns the injected time with its zone and offset', () async {
    final value = DateTime(2026, 11, 26, 14, 5);
    final useCase = GetCurrentTimeUseCase(now: () => value);

    final result = await useCase(const NoParams());

    final time = result.getOrElse(() => throw StateError('expected Right'));
    expect(time.local, value);
    expect(time.timeZoneName, value.timeZoneName);
    expect(time.utcOffset, value.timeZoneOffset);
  });
}
