import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/error/failure.dart';
import '../../../../core/use_cases/use_cases.dart';
import '../enums/app_theme_mode.dart';
import '../repositories/app_settings_repository.dart';

/// Returns `true` when the theme mode changed.
@injectable
class ChangeThemeModeUseCase extends UseCase<bool, AppThemeMode> {
  ChangeThemeModeUseCase({required this.appSettingsRepository});

  final AppSettingsRepository appSettingsRepository;

  @override
  Future<Either<Failure, bool>> call(AppThemeMode params) =>
      appSettingsRepository.setThemeMode(params);
}
