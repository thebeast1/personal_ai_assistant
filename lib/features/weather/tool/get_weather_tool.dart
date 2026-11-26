import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:injectable/injectable.dart';

import '../../../core/network/error/failure.dart';
import '../../../core/tools/app_tool.dart';
import '../../../core/tools/tool_result.dart';
import '../domain/params/get_weather_params.dart';
import '../domain/use_cases/get_current_weather_use_case.dart';

/// Lets Gemma look up the current weather. The bridge between the model and
/// the weather feature: validates the model's arguments, calls the use case
/// and turns the result into a [ToolResult].
@injectable
class GetWeatherTool extends AppTool {
  GetWeatherTool({required this.getCurrentWeatherUseCase});

  final GetCurrentWeatherUseCase getCurrentWeatherUseCase;

  static const toolName = 'get_weather';

  @override
  Tool get definition => const Tool(
    name: toolName,
    description:
        'Get the current weather for a city. Use when the user asks '
        'about weather, temperature or whether to take an umbrella.',
    parameters: {
      'type': 'object',
      'properties': {
        'city': {
          'type': 'string',
          'description':
              'City name as the user wrote it, e.g. Cairo or القاهرة',
        },
      },
      'required': ['city'],
    },
  );

  @override
  Future<ToolResult> execute(Map<String, dynamic> args) async {
    final city = args['city'];
    if (city is! String || city.trim().isEmpty) {
      return const ToolFailure(
        code: 'invalid_arguments',
        message: 'A city name is required.',
      );
    }

    final result = await getCurrentWeatherUseCase(
      GetWeatherParams(city: city.trim()),
    );
    return result.fold(
      (failure) => ToolFailure(code: _code(failure), message: failure.message),
      (weather) => ToolSuccess(weather.toJson()),
    );
  }

  String _code(Failure failure) => switch (failure) {
    NotFoundFailure() => 'city_not_found',
    NetworkFailure() => 'no_internet',
    _ => 'service_unavailable',
  };
}
