import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/auth/app_user.dart';
import 'package:humsafar_frontend/core/auth/current_user_provider.dart';
import 'package:humsafar_frontend/core/network/api_client.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/core/network/providers.dart';
import 'package:humsafar_frontend/features/dependent/screens/panic_screen.dart';
import 'package:humsafar_frontend/features/dependent/widgets/panic_hold_button.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

/// TC-3.11-04..09 — soft test cases for Task 3.11's Panic screen. Widget
/// tests against a fake ApiClient (same "soft test" convention as
/// live_map_screen_test.dart) — no login, no device. Unlike
/// DependentHomeScreen, this screen never touches a real plugin
/// (geolocator etc.), so the whole screen is testable end to end,
/// including navigation, via a tiny in-test GoRouter with stub
/// destinations instead of the app's real router.
class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.getHandler, this.postHandler, this.postError})
      : super(
          readAccessToken: () async => 'fake-token',
          readRefreshToken: () async => null,
          saveTokens: ({required String accessToken, required String refreshToken}) async {},
        );

  final Map<String, dynamic> Function(String path)? getHandler;
  final Map<String, dynamic> Function(String path)? postHandler;
  final ApiException? postError;
  int postCalls = 0;

  @override
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    final body = getHandler?.call(path) ?? <String, dynamic>{};
    return Response<T>(requestOptions: RequestOptions(path: path), data: body as T, statusCode: 200);
  }

  @override
  Future<Response<T>> post<T>(String path, {Object? data}) async {
    postCalls++;
    if (postError != null) throw postError!;
    final body = postHandler?.call(path) ?? <String, dynamic>{};
    return Response<T>(requestOptions: RequestOptions(path: path), data: body as T, statusCode: 200);
  }
}

const _testUser = AppUser(
  userId: 'dep-1',
  email: 'dep@example.com',
  phone: '03001234567',
  fullName: 'Test Dependent',
  role: 'dependent',
  guardianRole: null,
);

Widget _wrap(ApiClient fakeClient) {
  final router = GoRouter(
    initialLocation: '/panic-under-test',
    routes: [
      GoRoute(path: '/panic-under-test', builder: (context, state) => const PanicScreen()),
      GoRoute(path: '/dependent', builder: (context, state) => const Text('DEPENDENT_HOME_STUB')),
    ],
  );
  return ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(fakeClient),
      currentUserProvider.overrideWith((ref) => _testUser),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  testWidgets('TC-3.11-04: no panic open — shows the hold-to-confirm screen', (tester) async {
    final fakeClient = _FakeApiClient(getHandler: (_) => {'active': false, 'panic': null});

    await tester.pumpWidget(_wrap(fakeClient));
    await tester.pumpAndSettle();

    expect(find.text('Need help?'), findsOneWidget);
    expect(find.text('HOLD'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.11-05: a panic already open on arrival shows "Help is coming" directly, no hold UI', (tester) async {
    final fakeClient = _FakeApiClient(
        getHandler: (_) => {
              'active': true,
              'panic': {
                'event_id': 'evt-1',
                'status': 'open',
                'tier': 'primary',
                'triggered_at': '2026-10-20T08:00:00Z',
                'acknowledged_at': null,
                'resolved_at': null,
                'notified': 2,
                'already_active': true,
              },
            });

    await tester.pumpWidget(_wrap(fakeClient));
    await tester.pumpAndSettle();

    expect(find.text('Help is coming'), findsNWidgets(2));
    expect(find.text('We told 2 Guardian(s)'), findsOneWidget);
    expect(find.text('Waiting for a Guardian to see this'), findsOneWidget);
    expect(find.text('I am safe now'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.11-06: holding the button POSTs /panic and switches to "Help is coming"', (tester) async {
    final fakeClient = _FakeApiClient(
      getHandler: (_) => {'active': false, 'panic': null},
      postHandler: (path) => {
        'event_id': 'evt-2',
        'status': 'open',
        'tier': 'primary',
        'triggered_at': '2026-10-20T08:00:00Z',
        'acknowledged_at': null,
        'resolved_at': null,
        'notified': 3,
        'already_active': false,
      },
    );

    await tester.pumpWidget(_wrap(fakeClient));
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(tester.getCenter(find.byType(PanicHoldButton)));
    // Baseline frame before advancing the clock — see the comment on
    // TC-3.11-01 in panic_hold_button_test.dart for why this is required.
    await tester.pump();
    await tester.pump(const Duration(seconds: 2, milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, 1);
    expect(find.text('Help is coming'), findsNWidgets(2));
    expect(find.text('We told 3 Guardian(s)'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.11-07: a failed trigger shows an error and stays on the hold screen', (tester) async {
    final fakeClient = _FakeApiClient(
      getHandler: (_) => {'active': false, 'panic': null},
      postError: const ApiException(code: 'unexpected_error', message: 'boom'),
    );

    await tester.pumpWidget(_wrap(fakeClient));
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(tester.getCenter(find.byType(PanicHoldButton)));
    // Baseline frame before advancing the clock — see the comment on
    // TC-3.11-01 in panic_hold_button_test.dart for why this is required.
    await tester.pump();
    await tester.pump(const Duration(seconds: 2, milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Need help?'), findsOneWidget);
    expect(find.text("Couldn't send the alert. Check your connection and try again."), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.11-08: an escalated tier shows the emergency-contact note', (tester) async {
    final fakeClient = _FakeApiClient(
        getHandler: (_) => {
              'active': true,
              'panic': {
                'event_id': 'evt-3',
                'status': 'open',
                'tier': 'external_contact',
                'triggered_at': '2026-10-20T08:00:00Z',
                'acknowledged_at': null,
                'resolved_at': null,
                'notified': 1,
                'already_active': true,
              },
            });

    await tester.pumpWidget(_wrap(fakeClient));
    await tester.pumpAndSettle();

    expect(find.text('This has reached your emergency contact.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.11-09: "I am safe now" calls resolve and leaves the Panic screen', (tester) async {
    final fakeClient = _FakeApiClient(
      getHandler: (_) => {
        'active': true,
        'panic': {
          'event_id': 'evt-4',
          'status': 'open',
          'tier': 'primary',
          'triggered_at': '2026-10-20T08:00:00Z',
          'acknowledged_at': '2026-10-20T08:01:00Z',
          'resolved_at': null,
          'notified': 2,
          'already_active': true,
        },
      },
      postHandler: (path) => {'event_id': 'evt-4', 'status': 'resolved'},
    );

    await tester.pumpWidget(_wrap(fakeClient));
    await tester.pumpAndSettle();

    expect(find.text('I am safe now'), findsOneWidget);
    await tester.tap(find.text('I am safe now'));
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, 1);
    expect(find.text('DEPENDENT_HOME_STUB'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
