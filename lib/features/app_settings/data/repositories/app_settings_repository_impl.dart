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
    (settings) =>
        // With nothing saved the app shows the phone's language, so asking
        // for that one changes nothing (and keeps following the phone).
        (settings.language ?? _dataSource.deviceLanguage()) == language
        ? settings
        : settings.copyWith(language: language),
    () => _dataSource.saveLanguage(language),
  );

  @override
  Future<Either<Failure, bool>> setThemeMode(AppThemeMode mode) => _update(
    (settings) => settings.copyWith(themeMode: mode),
    () => _dataSource.saveThemeMode(mode),
  );

  /// Writes run one at a time, each starting from the settings the previous
  /// one left, so a button tap during a tool's save can't undo it.
  Future<void> _queue = Future.value();

  Future<Either<Failure, bool>> _update(
    AppSettings Function(AppSettings) change,
    Future<void> Function() save,
  ) {
    final result = _queue.then((_) => _apply(change(_current), save));
    _queue = result;
    return result;
  }

  /// Saves first, then updates [current] and emits, so a failed save
  /// changes nothing.
  Future<Either<Failure, bool>> _apply(
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
