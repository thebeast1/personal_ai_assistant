import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/app_settings/data/data_sources/app_settings_local_data_source.dart';

/// Loaded once before `runApp`, so the first frame already uses the saved
/// language and theme. Add a key to [allowList] before reading or writing it.
@module
abstract class StorageInjection {
  @preResolve
  @singleton
  Future<SharedPreferencesWithCache> get prefs =>
      SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(
          allowList: {
            AppSettingsLocalDataSourceImpl.languageKey,
            AppSettingsLocalDataSourceImpl.themeModeKey,
          },
        ),
      );
}
