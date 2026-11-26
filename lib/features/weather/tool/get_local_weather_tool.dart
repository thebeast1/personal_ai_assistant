import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:injectable/injectable.dart';

import '../../../core/network/error/failure.dart';

import '../../../core/tools/app_tool.dart';
import '../../../core/tools/tool_result.dart';
import '../../../core/use_cases/use_cases.dart';
import '../domain/use_cases/get_local_weather_use_case.dart';
import 'weather_failure_code.dart';

/// Weather where the user is. Takes no arguments: location permission is
/// asked the first time this runs. When there's no location, Gemma is told to
/// ask the user for their city and use `get_weather` with it.
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
      (failure) => failure is LocationFailure
          ? const ToolFailure(
              code: 'location_unavailable',
              message:
                  "Could not get the user's location. Ask the user which "
                  'city they are in, then call get_weather with that city.',
            )
          : ToolFailure(
              code: weatherFailureCode(failure),
              message: failure.message,
            ),
      (weather) => ToolSuccess(weather.toJson()),
    );
  }
}
