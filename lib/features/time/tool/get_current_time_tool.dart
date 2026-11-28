import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:injectable/injectable.dart';

import '../../../core/tools/app_tool.dart';
import '../../../core/tools/tool_result.dart';
import '../../../core/use_cases/use_cases.dart';
import '../domain/entities/current_time.dart';
import '../domain/use_cases/get_current_time_use_case.dart';

/// The time, date and weekday from the phone's clock. Gemma has no clock of
/// its own, so without this it would guess.
@injectable
class GetCurrentTimeTool extends AppTool {
  GetCurrentTimeTool({required this.getCurrentTimeUseCase});

  final GetCurrentTimeUseCase getCurrentTimeUseCase;

  static const toolName = 'get_current_time';

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Tool get definition => const Tool(
    name: toolName,
    description:
        'Get the current local time, date and day of the week. Use when the '
        "user asks what time it is, today's date, or what day it is.",
    parameters: {'type': 'object', 'properties': {}, 'required': []},
  );

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final result = await getCurrentTimeUseCase(const NoParams());
    return result.fold(
      (failure) =>
          ToolFailure(code: 'time_unavailable', message: failure.message),
      (time) => ToolSuccess(_toJson(time)),
    );
  }

  /// 24-hour time and an ISO date, so Gemma can phrase them in any language.
  static Map<String, dynamic> _toJson(CurrentTime time) {
    final t = time.local;
    return {
      'time': '${_two(t.hour)}:${_two(t.minute)}',
      'date': '${t.year}-${_two(t.month)}-${_two(t.day)}',
      'weekday': _weekdays[t.weekday - 1],
      'timezone': time.timeZoneName,
      'utc_offset': _offset(time.utcOffset),
    };
  }

  static String _offset(Duration offset) {
    final sign = offset.isNegative ? '-' : '+';
    final minutes = offset.inMinutes.abs();
    return '$sign${_two(minutes ~/ 60)}:${_two(minutes % 60)}';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
