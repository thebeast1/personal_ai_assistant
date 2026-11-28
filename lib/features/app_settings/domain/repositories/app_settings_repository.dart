import 'package:dartz/dartz.dart';

import '../../../../core/network/error/failure.dart';
import '../entities/app_settings.dart';
import '../enums/app_language.dart';
import '../enums/app_theme_mode.dart';

abstract class AppSettingsRepository {
  AppSettings get current;

  /// Emits the new settings after each saved change.
  Stream<AppSettings> get changes;

  /// `Right(true)` when it changed, `Right(false)` when it was already set.
  Future<Either<Failure, bool>> setLanguage(AppLanguage language);

  Future<Either<Failure, bool>> setThemeMode(AppThemeMode mode);
}
