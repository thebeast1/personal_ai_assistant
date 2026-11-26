// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/chat/data/data_sources/chat_data_source.dart' as _i665;
import '../../features/chat/data/repositories/chat_repository_impl.dart'
    as _i504;
import '../../features/chat/domain/repositories/chat_repository.dart' as _i420;
import '../../features/chat/domain/use_cases/clear_chat_use_case.dart' as _i417;
import '../../features/chat/domain/use_cases/init_chat_use_case.dart' as _i14;
import '../../features/chat/domain/use_cases/send_message_use_case.dart'
    as _i460;
import '../../features/weather/data/data_sources/weather_remote_data_source.dart'
    as _i1054;
import '../../features/weather/data/repositories/weather_repository_impl.dart'
    as _i231;
import '../../features/weather/domain/repositories/weather_repository.dart'
    as _i956;
import '../../features/weather/domain/use_cases/get_current_weather_use_case.dart'
    as _i664;
import '../../features/weather/tool/get_weather_tool.dart' as _i663;
import '../network/web_service/dio_impl.dart' as _i1033;
import '../network/web_service/network_helper.dart' as _i873;
import '../tools/tool_registry.dart' as _i258;
import '../tools/tool_result_views.dart' as _i476;
import 'injection.dart' as _i464;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final toolsInjection = _$ToolsInjection();
    gh.lazySingleton<_i476.ToolResultViews>(
      () => toolsInjection.toolResultViews,
    );
    gh.lazySingleton<_i873.NetworkHelper>(() => _i1033.DioImpl());
    gh.factory<_i1054.WeatherRemoteDataSource>(
      () => _i1054.WeatherRemoteDataSourceImpl(
        networkHelper: gh<_i873.NetworkHelper>(),
      ),
    );
    gh.factory<_i956.WeatherRepository>(
      () => _i231.WeatherRepositoryImpl(
        weatherRemoteDataSource: gh<_i1054.WeatherRemoteDataSource>(),
      ),
    );
    gh.factory<_i664.GetCurrentWeatherUseCase>(
      () => _i664.GetCurrentWeatherUseCase(
        weatherRepository: gh<_i956.WeatherRepository>(),
      ),
    );
    gh.factory<_i663.GetWeatherTool>(
      () => _i663.GetWeatherTool(
        getCurrentWeatherUseCase: gh<_i664.GetCurrentWeatherUseCase>(),
      ),
    );
    gh.lazySingleton<_i258.ToolRegistry>(
      () => toolsInjection.toolRegistry(gh<_i663.GetWeatherTool>()),
    );
    gh.lazySingleton<_i665.ChatDataSource>(
      () => _i665.ChatDataSourceImpl(toolRegistry: gh<_i258.ToolRegistry>()),
    );
    gh.lazySingleton<_i420.ChatRepository>(
      () =>
          _i504.ChatRepositoryImpl(chatDataSource: gh<_i665.ChatDataSource>()),
    );
    gh.factory<_i417.ClearChatUseCase>(
      () => _i417.ClearChatUseCase(chatRepository: gh<_i420.ChatRepository>()),
    );
    gh.factory<_i14.InitChatUseCase>(
      () => _i14.InitChatUseCase(chatRepository: gh<_i420.ChatRepository>()),
    );
    gh.factory<_i460.SendMessageUseCase>(
      () =>
          _i460.SendMessageUseCase(chatRepository: gh<_i420.ChatRepository>()),
    );
    return this;
  }
}

class _$ToolsInjection extends _i464.ToolsInjection {}
