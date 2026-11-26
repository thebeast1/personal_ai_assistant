import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/error/failure.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/enums/app_language.dart';
import '../../domain/enums/app_theme_mode.dart';
import '../../domain/repositories/app_settings_repository.dart';
import '../data_sources/app_settings_local_data_source.dart';

/// The one source of truth for the language and theme. Tools and the app
/// bar button change it; `AppSettingsProvider` listens to [changes].
@LazySingleton(as: AppSettingsRepository)
class AppSettingsRepositoryImpl implements AppSettingsRepository {
  AppSettingsRepositoryImpl(this._dataSource) : _current = _dataSource.read();

  final AppSettingsLocalDataSource _dataSource;
  final _changes = StreamController<AppSettings>.broadcast();
  AppSettings _current;

  @override
  AppSettings get current => _current;

  @override
  Stream<AppSettings> get changes => _changes.stream;

  @override
  Future<Either<Failure, bool>> setLanguage(AppLanguage language) => _update(
    _current.copyWith(language: language),
    () => _dataSource.saveLanguage(language),
  );

  @override
  Future<Either<Failure, bool>> setThemeMode(AppThemeMode mode) => _update(
    _current.copyWith(themeMode: mode),
    () => _dataSource.saveThemeMode(mode),
  );

  /// Saves first, then updates [current] and emits, so a failed save
  /// changes nothing.
  Future<Either<Failure, bool>> _update(
    AppSettings next,
    Future<void> Function() save,
  ) async {
    if (next == _current) return const Right(false);
    try {
      await save();
    } catch (_) {
      return Left(CacheFailure());
    }
    _current = next;
    _changes.add(next);
    return const Right(true);
  }
}
