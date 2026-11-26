import 'package:dartz/dartz.dart';

import '../../../../core/network/error/failure.dart';
import '../../data/models/location_model.dart';

abstract class LocationRepository {
  Future<Either<Failure, LocationModel>> getCurrentLocation();
}
