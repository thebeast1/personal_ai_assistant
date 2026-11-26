import 'package:dio/dio.dart';

/// The HTTP contract data sources depend on. [DioImpl] is the real one;
/// tests can mock this instead of Dio.
///
/// [url] is a full URL: each feature talks to its own API host, so there is
/// no shared base URL.
abstract class NetworkHelper {
  Future<dynamic> get({
    required String url,
    Map<String, dynamic>? queryParams,
    CancelToken? cancelToken,
  });

  Future<dynamic> post({
    required String url,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    CancelToken? cancelToken,
  });
}
