import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_ai_assistant/core/network/error/failure.dart';
import 'package:personal_ai_assistant/core/tools/tool_result.dart';
import 'package:personal_ai_assistant/core/use_cases/use_cases.dart';
import 'package:personal_ai_assistant/features/time/domain/entities/current_time.dart';
import 'package:personal_ai_assistant/features/time/domain/use_cases/get_current_time_use_case.dart';
import 'package:personal_ai_assistant/features/time/tool/get_current_time_tool.dart';

class _MockGetCurrentTime extends Mock implements GetCurrentTimeUseCase {}

void main() {
  late _MockGetCurrentTime useCase;
  late GetCurrentTimeTool tool;

  setUpAll(() => registerFallbackValue(const NoParams()));

  setUp(() {
    useCase = _MockGetCurrentTime();
    tool = GetCurrentTimeTool(getCurrentTimeUseCase: useCase);
  });

  void answer(CurrentTime time) =>
      when(() => useCase(any())).thenAnswer((_) async => Right(time));

  test('the definition takes no arguments', () {
    expect(tool.name, 'get_current_time');
    expect(tool.definition.parameters['required'], isEmpty);
  });

  test('formats an afternoon time', () async {
    answer(
      CurrentTime(
        local: DateTime(2026, 11, 26, 14, 5),
        timeZoneName: 'EET',
        utcOffset: const Duration(hours: 2),
      ),
    );

    final result = await tool.execute({}) as ToolSuccess;

    expect(result.data, {
      'time': '14:05',
      'date': '2026-11-26',
      'weekday': 'Thursday',
      'timezone': 'EET',
      'utc_offset': '+02:00',
    });
  });

  test('formats midnight and a negative half-hour offset', () async {
    answer(
      CurrentTime(
        local: DateTime(2027, 1, 3, 0, 7),
        timeZoneName: 'NST',
        utcOffset: const Duration(hours: -3, minutes: -30),
      ),
    );

    final result = await tool.execute({}) as ToolSuccess;

    expect(result.data['time'], '00:07');
    expect(result.data['date'], '2027-01-03');
    expect(result.data['weekday'], 'Sunday');
    expect(result.data['utc_offset'], '-03:30');
  });

  test('a failure becomes time_unavailable', () async {
    when(() => useCase(any())).thenAnswer((_) async => Left(ServerFailure()));

    final result = await tool.execute({}) as ToolFailure;

    expect(result.code, 'time_unavailable');
  });
}
