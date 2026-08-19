import 'package:dio/dio.dart';

/// Computes the Authorization header to attach to an outgoing request,
/// given a way to read the current access token. Deliberately a plain
/// function, not tied to Dio's Interceptor machinery, specifically so
/// it's trivially unit-testable without constructing any Dio internals —
/// see the accompanying test file.
Future<Map<String, String>> buildAuthHeaders(Future<String?> Function() readAccessToken) async {
  final token = await readAccessToken();
  return token == null ? {} : {'Authorization': 'Bearer $token'};
}

/// Attaches the stored JWT access token to every outgoing request, if one
/// exists. Takes a `readAccessToken` callback rather than a concrete
/// TokenStorage so it never has to know about flutter_secure_storage
/// directly — keeps this class (and its logic in [buildAuthHeaders])
/// decoupled from platform channels.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required Future<String?> Function() readAccessToken}) : _readAccessToken = readAccessToken;

  final Future<String?> Function() _readAccessToken;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    options.headers.addAll(await buildAuthHeaders(_readAccessToken));
    handler.next(options);
  }
}
