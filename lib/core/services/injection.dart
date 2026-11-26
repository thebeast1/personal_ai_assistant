import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

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
  ToolRegistry get toolRegistry => ToolRegistry([]);

  @lazySingleton
  ToolResultViews get toolResultViews => const ToolResultViews({});
}
