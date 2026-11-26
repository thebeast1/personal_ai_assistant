import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'network_helper.dart';

@LazySingleton(as: NetworkHelper)
class DioImpl implements NetworkHelper {
  DioImpl() : _dio = Dio() {
    _dio
      ..options.connectTimeout = kTimeout
      ..options.receiveTimeout = kTimeout
      ..interceptors.addAll([
        if (kDebugMode)
          PrettyDioLogger(requestBody: true, responseBody: true, error: true),
      ]);
  }

  /// Tools run while the user waits for a reply, so fail fast.
  static const kTimeout = Duration(seconds: 10);

  final Dio _dio;

  @visibleForTesting
  BaseOptions get options => _dio.options;

  @override
  Future<dynamic> get({
    required String url,
    Map<String, dynamic>? queryParams,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      url,
      queryParameters: queryParams,
      cancelToken: cancelToken,
    );
    return response.data;
  }

  @override
  Future<dynamic> post({
    required String url,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.post(
      url,
      data: body,
      queryParameters: queryParams,
      cancelToken: cancelToken,
    );
    return response.data;
  }
}
