import 'package:dartz/dartz.dart';

import '../network/error/failure.dart';

abstract class UseCase<ReturnType, Params> {
  Future<Either<Failure, ReturnType>> call(Params params);
}

class NoParams {
  const NoParams();
}
