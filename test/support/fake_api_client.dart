// test/support/fake_api_client.dart
//
// A shared, generic fake ApiClient for widget tests. Pulled out of
// panic_screen_test.dart and wellness_check_screen_test.dart (Tasks
// 3.11/3.12), which had each hand-rolled their own near-identical copy.
// Centralizing it here means every future screen's tests get the same
// already-tested behavior for free, instead of risking a
// slightly-different, slightly-buggy copy-paste each time.
//
// Supply only the handlers a given test actually needs; anything else
// defaults to an empty/no-op response.

import 'package:dio/dio.dart';
import 'package:humsafar_frontend/core/network/api_client.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient({this.getHandler, this.postHandler, this.getError, this.postError})
      : super(
          readAccessToken: () async => 'fake-token',
          readRefreshToken: () async => null,
          saveTokens: ({required String accessToken, required String refreshToken}) async {},
        );

  /// Called for every GET; return the decoded JSON body. If null, GET
  /// returns an empty map.
  final Map<String, dynamic> Function(String path)? getHandler;

  /// Called for every POST that doesn't throw [postError]; return the
  /// decoded JSON body. If null, POST returns an empty map.
  final Map<String, dynamic> Function(String path)? postHandler;

  /// If set, every GET throws this instead of calling [getHandler].
  final ApiException? getError;

  /// If set, every POST throws this instead of calling [postHandler].
  final ApiException? postError;

  /// How many times GET has been called.
  int getCalls = 0;

  /// How many times POST has been called.
  int postCalls = 0;

  /// The path of the most recent GET, or null if GET hasn't been called yet.
  String? lastGetPath;

  /// The path of the most recent POST, or null if POST hasn't been called yet.
  String? lastPostPath;

  @override
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    getCalls++;
    lastGetPath = path;
    if (getError != null) throw getError!;
    final body = getHandler?.call(path) ?? <String, dynamic>{};
    return Response<T>(requestOptions: RequestOptions(path: path), data: body as T, statusCode: 200);
  }

  @override
  Future<Response<T>> post<T>(String path, {Object? data}) async {
    postCalls++;
    lastPostPath = path;
    if (postError != null) throw postError!;
    final body = postHandler?.call(path) ?? <String, dynamic>{};
    return Response<T>(requestOptions: RequestOptions(path: path), data: body as T, statusCode: 200);
  }
}
