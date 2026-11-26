import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/error/failure.dart';
import '../../../../core/use_cases/use_cases.dart';
import '../enums/app_language.dart';
import '../repositories/app_settings_repository.dart';

/// Returns `true` when the language changed.
@injectable
class ChangeLanguageUseCase extends UseCase<bool, AppLanguage> {
  ChangeLanguageUseCase({required this.appSettingsRepository});

  final AppSettingsRepository appSettingsRepository;

  @override
  Future<Either<Failure, bool>> call(AppLanguage params) =>
      appSettingsRepository.setLanguage(params);
}
