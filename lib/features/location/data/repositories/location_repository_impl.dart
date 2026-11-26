import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/error/error_handler.dart';
import '../../../../core/network/error/failure.dart';
import '../../domain/repositories/location_repository.dart';
import '../data_sources/location_data_source.dart';
import '../models/location_model.dart';

@Injectable(as: LocationRepository)
class LocationRepositoryImpl implements LocationRepository {
  LocationRepositoryImpl({required this.locationDataSource});

  final LocationDataSource locationDataSource;

  @override
  Future<Either<Failure, LocationModel>> getCurrentLocation() async {
    try {
      return Right(await locationDataSource.getCurrentLocation());
    } catch (e) {
      return Left(ErrorHandler.handle(e).failure);
    }
  }
}
