import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/error/failure.dart';
import '../../../../core/use_cases/use_cases.dart';
import '../entities/current_time.dart';

/// Reads the phone's clock. Tests pass [now] to pin the time.
@injectable
class GetCurrentTimeUseCase extends UseCase<CurrentTime, NoParams> {
  GetCurrentTimeUseCase({@ignoreParam DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  @override
  Future<Either<Failure, CurrentTime>> call(NoParams params) async {
    final local = _now();
    return Right(
      CurrentTime(
        local: local,
        timeZoneName: local.timeZoneName,
        utcOffset: local.timeZoneOffset,
      ),
    );
  }
}
