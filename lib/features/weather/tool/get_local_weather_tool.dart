import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:injectable/injectable.dart';

import '../../../core/tools/app_tool.dart';
import '../../../core/tools/tool_result.dart';
import '../../../core/use_cases/use_cases.dart';
import '../domain/use_cases/get_local_weather_use_case.dart';
import 'weather_failure_code.dart';

/// Weather where the user is. Takes no arguments: location permission is
/// asked the first time this runs, and Cairo is used when there's no location.
@injectable
class GetLocalWeatherTool extends AppTool {
  GetLocalWeatherTool({required this.getLocalWeatherUseCase});

  final GetLocalWeatherUseCase getLocalWeatherUseCase;

  static const toolName = 'get_local_weather';

  @override
  Tool get definition => const Tool(
    name: toolName,
    description:
        'Get the current weather where the user is. Use when the user asks '
        'about the weather, temperature or an umbrella without naming a city.',
    parameters: {'type': 'object', 'properties': {}, 'required': []},
  );

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final result = await getLocalWeatherUseCase(const NoParams());
    return result.fold(
      (failure) => ToolFailure(
        code: weatherFailureCode(failure),
        message: failure.message,
      ),
      (local) => ToolSuccess({
        ...local.weather.toJson(),
        'source': local.source.apiName,
      }),
    );
  }
}
