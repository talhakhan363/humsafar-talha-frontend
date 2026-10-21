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
//
// Extended for Task 3.15 (2026-10-21): added `put` support
// (putHandler/putError/putCalls/lastPutPath), since the Guardian
// schedule screens are the first screens to call `ApiClient.put`, plus
// `lastPostData`/`lastPutData` so a test can assert the exact request
// body a screen sent, not just which path it hit. Purely additive -
// every existing get/post usage (Tasks 3.11/3.12's tests) is untouched.
//
// Extended for Task 3.14 (2026-10-21): added `delete` support
// (deleteHandler/deleteError/deleteCalls/lastDeletePath/
// lastDeleteQueryParameters), since push-token unregistration and the
// Emergency settings screen's "Remove contact" are the first callers of
// `ApiClient.delete`. `delete` has no request body in this app (both real
// callers use query parameters or none), so there's no `lastDeleteData`
// to match `lastPostData`/`lastPutData` - only the path and query params
// are captured. Purely additive, same as the `put` extension above.
//
// Also widened [getHandler] from `Map<String, dynamic> Function(String)`
// to `dynamic Function(String)`: MissedDoseScreen is the first screen
// under test that calls both a Map-returning GET
// (`/dependents/{id}/medication-doses`) AND a List-returning one
// (`/guardians/me/dependents`, `ApiClient.get<List<dynamic>>`) in the
// same load — the old Map-only signature couldn't represent a top-level
// JSON array response at all. Every existing test's handler already
// returns a `Map<String, dynamic>` literal, which is still a valid
// `dynamic`, so this is purely additive - nothing existing changes
// behavior.
//
// Extended for Task 4.6/4.8 (2026-10-22): `get` now also accepts (and
// ignores) the real `ApiClient.get`'s new `responseType` parameter —
// required simply to keep overriding a valid match for the base class's
// signature (Dart requires an override to accept every parameter its
// superclass method does). `getHandler` already returns `dynamic`, so a
// test for the voice-message download (`GET /messages/{id}/audio`) can
// just return a `List<int>` of fake bytes; the fake doesn't need to care
// that the real client would have asked for `ResponseType.bytes`.

import 'package:dio/dio.dart';
import 'package:humsafar_frontend/core/network/api_client.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient({
    this.getHandler,
    this.postHandler,
    this.putHandler,
    this.deleteHandler,
    this.getError,
    this.postError,
    this.putError,
    this.deleteError,
  }) : super(
          readAccessToken: () async => 'fake-token',
          readRefreshToken: () async => null,
          saveTokens: ({required String accessToken, required String refreshToken}) async {},
        );

  /// Called for every GET; return the decoded JSON body — a
  /// `Map<String, dynamic>` for an object response, a `List<dynamic>`
  /// for an array response, or a `List<int>` for a raw-bytes response
  /// (match whatever `ApiClient.get<T>`'s `T` is at the call site). If
  /// null, GET returns an empty map.
  final dynamic Function(String path)? getHandler;

  /// Called for every POST that doesn't throw [postError]; return the
  /// decoded JSON body. If null, POST returns an empty map. The handler
  /// itself may throw an [ApiException] (e.g. to make only *some* POSTs
  /// to a given screen fail) instead of using [postError], which applies
  /// to every POST unconditionally.
  final Map<String, dynamic> Function(String path)? postHandler;

  /// Called for every PUT that doesn't throw [putError]; return the
  /// decoded JSON body. If null, PUT returns an empty map. Same
  /// "handler may throw itself" note as [postHandler] applies.
  final Map<String, dynamic> Function(String path)? putHandler;

  /// Called for every DELETE that doesn't throw [deleteError]; return the
  /// decoded JSON body. If null, DELETE returns an empty map. Same
  /// "handler may throw itself" note as [postHandler] applies.
  final Map<String, dynamic> Function(String path)? deleteHandler;

  /// If set, every GET throws this instead of calling [getHandler].
  final ApiException? getError;

  /// If set, every POST throws this instead of calling [postHandler].
  final ApiException? postError;

  /// If set, every PUT throws this instead of calling [putHandler].
  final ApiException? putError;

  /// If set, every DELETE throws this instead of calling [deleteHandler].
  final ApiException? deleteError;

  /// How many times GET has been called.
  int getCalls = 0;

  /// How many times POST has been called.
  int postCalls = 0;

  /// How many times PUT has been called.
  int putCalls = 0;

  /// How many times DELETE has been called.
  int deleteCalls = 0;

  /// The path of the most recent GET, or null if GET hasn't been called yet.
  String? lastGetPath;

  /// The path of the most recent POST, or null if POST hasn't been called yet.
  String? lastPostPath;

  /// The path of the most recent PUT, or null if PUT hasn't been called yet.
  String? lastPutPath;

  /// The path of the most recent DELETE, or null if DELETE hasn't been
  /// called yet.
  String? lastDeletePath;

  /// The `queryParameters` of the most recent DELETE, or null if DELETE
  /// hasn't been called yet (or was called with none).
  Map<String, dynamic>? lastDeleteQueryParameters;

  /// The `data` argument of the most recent POST, or null if POST hasn't
  /// been called yet (or was called with no body). For a multipart send
  /// (Task 4.8's urgent voice message), this is the `FormData` instance
  /// itself — a test asserts on it via `.fields`/`.files`.
  dynamic lastPostData;

  /// The `data` argument of the most recent PUT, or null if PUT hasn't
  /// been called yet (or was called with no body).
  dynamic lastPutData;

  @override
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters, ResponseType? responseType}) async {
    getCalls++;
    lastGetPath = path;
    if (getError != null) throw getError!;
    final dynamic body = getHandler?.call(path) ?? <String, dynamic>{};
    return Response<T>(requestOptions: RequestOptions(path: path), data: body as T, statusCode: 200);
  }

  @override
  Future<Response<T>> post<T>(String path, {Object? data}) async {
    postCalls++;
    lastPostPath = path;
    lastPostData = data;
    if (postError != null) throw postError!;
    final body = postHandler?.call(path) ?? <String, dynamic>{};
    return Response<T>(requestOptions: RequestOptions(path: path), data: body as T, statusCode: 200);
  }

  @override
  Future<Response<T>> put<T>(String path, {Object? data}) async {
    putCalls++;
    lastPutPath = path;
    lastPutData = data;
    if (putError != null) throw putError!;
    final body = putHandler?.call(path) ?? <String, dynamic>{};
    return Response<T>(requestOptions: RequestOptions(path: path), data: body as T, statusCode: 200);
  }

  @override
  Future<Response<T>> delete<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    deleteCalls++;
    lastDeletePath = path;
    lastDeleteQueryParameters = queryParameters;
    if (deleteError != null) throw deleteError!;
    final body = deleteHandler?.call(path) ?? <String, dynamic>{};
    return Response<T>(requestOptions: RequestOptions(path: path), data: body as T, statusCode: 200);
  }
}
