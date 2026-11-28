import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/error/failure.dart';
import '../../../../core/use_cases/use_cases.dart';
import '../../data/models/location_model.dart';
import '../repositories/location_repository.dart';

@injectable
class GetCurrentLocationUseCase extends UseCase<LocationModel, NoParams> {
  GetCurrentLocationUseCase({required this.locationRepository});

  final LocationRepository locationRepository;

  @override
  Future<Either<Failure, LocationModel>> call(NoParams params) async =>
      await locationRepository.getCurrentLocation();
}
