import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humsafar_frontend/core/network/api_client.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/core/network/providers.dart';
import 'package:humsafar_frontend/features/guardian/screens/live_map_screen.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

/// TC-2.6-01 (revised) / TC-2.6-08 — soft test cases for Task 2.6, Live Map.
///
/// Team decision 2026-10-20: a "soft"/smoke test case must not require
/// login or a linked Guardian/Dependent pair. These are widget tests —
/// they mount the real LiveMapScreen against a fake ApiClient that
/// returns canned JSON instead of a real backend. No login, no Postman,
/// no device. Run with `flutter test`.
///
/// What these do NOT cover: whether the map tiles/marker/circle actually
/// render correctly on a real device — that can only be judged by eye,
/// so it stays a manual check in the full team test pass at the end
/// (see the deferred rows in the test case log).
class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.handler)
      : super(
          readAccessToken: () async => 'fake-token',
          readRefreshToken: () async => null,
          saveTokens: ({required String accessToken, required String refreshToken}) async {},
        );

  final Map<String, dynamic> Function(String path) handler;

  @override
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    final body = handler(path);
    return Response<T>(requestOptions: RequestOptions(path: path), data: body as T, statusCode: 200);
  }
}

class _ThrowingFakeApiClient extends ApiClient {
  _ThrowingFakeApiClient(this.exception)
      : super(
          readAccessToken: () async => 'fake-token',
          readRefreshToken: () async => null,
          saveTokens: ({required String accessToken, required String refreshToken}) async {},
        );

  final ApiException exception;

  @override
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    throw exception;
  }
}

Widget _wrap(ApiClient fakeClient) {
  return ProviderScope(
    overrides: [apiClientProvider.overrideWithValue(fakeClient)],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LiveMapScreen(dependentId: 'dep-1', dependentLabel: 'Test Dependent'),
    ),
  );
}

void main() {
  testWidgets('TC-2.6-01: shows "not linked" error + Retry when the API denies access', (tester) async {
    final fakeClient = _ThrowingFakeApiClient(
      const ApiException(code: 'NOT_LINKED_TO_DEPENDENT', message: 'ignored in test'),
    );

    await tester.pumpWidget(_wrap(fakeClient));
    await tester.pumpAndSettle();

    expect(find.text("You're not linked to this Dependent."), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);

    // Swap the tree out so the screen's periodic Timer is disposed/cancelled
    // before the test ends, instead of leaking past it.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-2.6-08: shows "no location yet" + "no safe zones" when the Dependent has never sent a fix', (tester) async {
    final fakeClient = _FakeApiClient((path) {
      if (path.endsWith('/geofence-status')) return {'status': 'no_zones'};
      if (path.endsWith('/geofences')) return {'geofences': []};
      return {'location': null, 'age_seconds': null, 'is_stale': true}; // .../location
    });

    await tester.pumpWidget(_wrap(fakeClient));
    await tester.pumpAndSettle();

    expect(find.text('No safe zones set up yet'), findsOneWidget);
    expect(find.text('No location received yet.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
