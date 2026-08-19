import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'auth_interceptor.dart';

/// Thin wrapper around Dio so every screen talks to one shared client
/// instead of constructing its own — base URL and the auth interceptor
/// live here, once. Every call normalizes failures into [ApiException],
/// so calling code only ever deals with one exception type, never a raw
/// DioException.
///
/// NOTE: `baseUrl` defaults to a local placeholder — point it at
/// Abdullah's actual dev server address once Task 2.5 starts wiring real
/// calls. Nothing else in this class should need to change when that
/// happens.
class ApiClient {
  ApiClient({
    required Future<String?> Function() readAccessToken,
    Dio? dio,
    String baseUrl = 'http://localhost:8000',
  }) : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl)) {
    _dio.interceptors.add(AuthInterceptor(readAccessToken: readAccessToken));
  }

  final Dio _dio;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) =>
      _wrap(() => _dio.get<T>(path, queryParameters: queryParameters));

  Future<Response<T>> post<T>(String path, {Object? data}) => _wrap(() => _dio.post<T>(path, data: data));

  Future<Response<T>> _wrap<T>(Future<Response<T>> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        throw ApiException.fromJson(data, statusCode: e.response?.statusCode);
      }
      throw ApiException.unexpected(e.message ?? 'Network error', statusCode: e.response?.statusCode);
    }
  }
}
