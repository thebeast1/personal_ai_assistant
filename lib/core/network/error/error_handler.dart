import 'package:dio/dio.dart';

import 'app_exceptions.dart';
import 'failure.dart';

/// Turns any error thrown by a data source into a [Failure].
///
/// Usage in a repository:
/// `return Left(ErrorHandler.handle(e).failure);`
class ErrorHandler implements Exception {
  late Failure failure;

  ErrorHandler.handle(dynamic error) {
    if (error is DioException) {
      failure = _handleError(error);
    } else if (error is NotFoundException) {
      failure = NotFoundFailure(error: error.message);
    } else if (error is LocationPermissionDeniedException ||
        error is LocationUnavailableException) {
      failure = LocationFailure();
    } else {
      failure = ServerFailure();
    }
  }
}

Failure _handleError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return NetworkFailure();
    case DioExceptionType.badResponse:
      return _handleBadResponse(error);
    case DioExceptionType.transformTimeout:
    case DioExceptionType.badCertificate:
    case DioExceptionType.cancel:
    case DioExceptionType.unknown:
      return ServerFailure();
  }
}

Failure _handleBadResponse(DioException error) {
  switch (error.response?.statusCode) {
    case 404:
      return NotFoundFailure();
    default:
      return ServerFailure();
  }
}
