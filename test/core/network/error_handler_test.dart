import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_ai_assistant/core/network/error/app_exceptions.dart';
import 'package:personal_ai_assistant/core/network/error/error_handler.dart';
import 'package:personal_ai_assistant/core/network/error/failure.dart';

DioException _dioError(DioExceptionType type, {int? statusCode}) {
  final options = RequestOptions(path: '/test');
  return DioException(
    requestOptions: options,
    type: type,
    response: statusCode == null
        ? null
        : Response(requestOptions: options, statusCode: statusCode),
  );
}

void main() {
  group('ErrorHandler.handle', () {
    test('no connection or timeouts become NetworkFailure', () {
      for (final type in [
        DioExceptionType.connectionError,
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(
          ErrorHandler.handle(_dioError(type)).failure,
          isA<NetworkFailure>(),
          reason: type.name,
        );
      }
    });

    test('a 404 response becomes NotFoundFailure', () {
      final failure = ErrorHandler.handle(
        _dioError(DioExceptionType.badResponse, statusCode: 404),
      ).failure;
      expect(failure, isA<NotFoundFailure>());
    });

    test('a 500 response becomes ServerFailure', () {
      final failure = ErrorHandler.handle(
        _dioError(DioExceptionType.badResponse, statusCode: 500),
      ).failure;
      expect(failure, isA<ServerFailure>());
    });

    test('NotFoundException keeps its message', () {
      final failure = ErrorHandler.handle(
        const NotFoundException('No city called Blorptown'),
      ).failure;
      expect(failure, isA<NotFoundFailure>());
      expect(failure.message, 'No city called Blorptown');
    });

    test('location exceptions become LocationFailure', () {
      expect(
        ErrorHandler.handle(const LocationPermissionDeniedException()).failure,
        isA<LocationFailure>(),
      );
      expect(
        ErrorHandler.handle(const LocationUnavailableException()).failure,
        isA<LocationFailure>(),
      );
    });

    test('anything else becomes ServerFailure', () {
      expect(
        ErrorHandler.handle(const FormatException('bad json')).failure,
        isA<ServerFailure>(),
      );
    });

    test('every failure has a non-empty message', () {
      for (final failure in [
        ServerFailure(),
        NetworkFailure(),
        NotFoundFailure(),
        LocationFailure(),
      ]) {
        expect(failure.message, isNotEmpty);
      }
    });
  });
}
