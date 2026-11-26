import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

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
