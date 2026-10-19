import 'package:dio/dio.dart';

import 'api_config.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

/// Thin wrapper around Dio so every screen talks to one shared client
/// instead of constructing its own — base URL and the auth interceptor
/// live here, once. Every call normalizes failures into [ApiException],
/// so calling code only ever deals with one exception type, never a raw
/// DioException.
///
/// Also owns the 15-minute access-token refresh flow (SDS 11.3 / the auth
/// contract's suggested client flow): on a 401 `TOKEN_EXPIRED`, it calls
/// `/auth/refresh` once, saves the new pair, and retries the original
/// request exactly once. If that fails too, the original `ApiException`
/// propagates — screens should treat a `TOKEN_EXPIRED`/`TOKEN_INVALID`
/// that reaches them as "session is gone, go to login."
class ApiClient {
  ApiClient({
    required Future<String?> Function() readAccessToken,
    required Future<String?> Function() readRefreshToken,
    required Future<void> Function({required String accessToken, required String refreshToken}) saveTokens,
    Dio? dio,
    String baseUrl = apiBaseUrl,
  })  : _readRefreshToken = readRefreshToken,
        _saveTokens = saveTokens,
        _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl)) {
    _dio.interceptors.add(AuthInterceptor(readAccessToken: readAccessToken));
  }

  final Dio _dio;
  final Future<String?> Function() _readRefreshToken;
  final Future<void> Function({required String accessToken, required String refreshToken}) _saveTokens;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) =>
      _wrap(() => _dio.get<T>(path, queryParameters: queryParameters));

  Future<Response<T>> post<T>(String path, {Object? data}) => _wrap(() => _dio.post<T>(path, data: data));

  Future<Response<T>> put<T>(String path, {Object? data}) => _wrap(() => _dio.put<T>(path, data: data));

  Future<Response<T>> _wrap<T>(Future<Response<T>> Function() request, {bool isRetry = false}) async {
    try {
      return await request();
    } on DioException catch (e) {
      final data = e.response?.data;
      // Real envelope is { "error": { "code", "message", "details" } } —
      // not the fields at the top level. This was the bug: unwrap it here.
      final envelope = data is Map<String, dynamic> ? data['error'] : null;
      final code = envelope is Map<String, dynamic> ? envelope['code'] as String? : null;

      if (code == 'TOKEN_EXPIRED' && !isRetry) {
        if (await _tryRefresh()) {
          return _wrap(request, isRetry: true);
        }
      }

      if (envelope is Map<String, dynamic>) {
        throw ApiException.fromJson(envelope, statusCode: e.response?.statusCode);
      }
      throw ApiException.unexpected(e.message ?? 'Network error', statusCode: e.response?.statusCode);
    }
  }

  Future<bool> _tryRefresh() async {
    final refreshToken = await _readRefreshToken();
    if (refreshToken == null) return false;
    try {
      final response = await _dio.post<Map<String, dynamic>>('/auth/refresh', data: {'refresh_token': refreshToken});
      final body = response.data;
      if (body == null) return false;
      await _saveTokens(accessToken: body['access_token'] as String, refreshToken: body['refresh_token'] as String);
      return true;
    } on DioException {
      return false;
    }
  }
}
