import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../../features/time/tool/get_current_time_tool.dart';
import '../../features/weather/presentation/widgets/weather_card.dart';
import '../../features/weather/tool/get_local_weather_tool.dart';
import '../../features/weather/tool/get_weather_tool.dart';
import '../tools/tool_registry.dart';
import '../tools/tool_result_views.dart';
import 'injection.config.dart';

final sl = GetIt.instance;

/// Registers every `@injectable` / `@lazySingleton` class.
/// After adding or changing one, regenerate `injection.config.dart` with:
/// `dart run build_runner build --delete-conflicting-outputs`
@InjectableInit(
  initializerName: 'init', // default
  preferRelativeImports: true, // default
  asExtension: true, // default
)
void configureInjection() => sl.init();

/// The toolbox. This is the one place that knows every tool: add a feature's
/// tool to the list and its card to the map.
@module
abstract class ToolsInjection {
  @lazySingleton
  ToolRegistry toolRegistry(
    GetWeatherTool getWeatherTool,
    GetLocalWeatherTool getLocalWeatherTool,
    GetCurrentTimeTool getCurrentTimeTool,
  ) => ToolRegistry([getWeatherTool, getLocalWeatherTool, getCurrentTimeTool]);

  @lazySingleton
  ToolResultViews get toolResultViews => ToolResultViews({
    GetWeatherTool.toolName: (context, data) => WeatherCard(data: data),
    GetLocalWeatherTool.toolName: (context, data) => WeatherCard(data: data),
  });
}
