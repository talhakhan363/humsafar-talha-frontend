// Task 5.8 — TC-5.8-01..04. Connect band: empty-address validation,
// a successful pair (POST body, optional name), and the
// BAND_ALREADY_PAIRED error mapping.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/features/wearable/screens/connect_band_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

List<GoRoute> _routes() => [
      GoRoute(path: '/connect-band-under-test', builder: (_, __) => const ConnectBandScreen(dependentId: 'dep-1')),
    ];

// Adds a `/host` route in front of the screen under test — needed for
// any test that reaches `_pair()`'s `Navigator.of(context).pop(true)`.
// See `AutoPushHost`'s doc comment in widget_test_harness.dart.
List<GoRoute> _hostedRoutes() => [
      GoRoute(path: '/host', builder: (_, __) => const AutoPushHost(targetPath: '/connect-band-under-test')),
      ..._routes(),
    ];

void main() {
  testWidgets('TC-5.8-01: an empty address blocks Pair, no POST', (tester) async {
    final fakeClient = FakeApiClient();
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/connect-band-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Pair'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsOneWidget);
    expect(fakeClient.postCalls, 0);
  });

  testWidgets('TC-5.8-02: a valid address POSTs ble_address and an optional name', (tester) async {
    final fakeClient = FakeApiClient(postHandler: (_) => <String, dynamic>{});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/host', routes: _hostedRoutes()));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Bluetooth Address'), 'C4:5B:BE:12:34:56');
    await tester.enterText(find.widgetWithText(TextField, 'Band Name (optional)'), 'Dad\'s band');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Pair'));
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, 1);
    expect(fakeClient.lastPostPath, '/dependents/dep-1/wearable');
    expect(fakeClient.lastPostData, {'ble_address': 'C4:5B:BE:12:34:56', 'name': "Dad's band"});
  });

  testWidgets('TC-5.8-03: omitting the name field sends no name key', (tester) async {
    final fakeClient = FakeApiClient(postHandler: (_) => <String, dynamic>{});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/host', routes: _hostedRoutes()));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Bluetooth Address'), 'C4:5B:BE:12:34:56');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Pair'));
    await tester.pumpAndSettle();

    expect(fakeClient.lastPostData, {'ble_address': 'C4:5B:BE:12:34:56'});
  });

  testWidgets('TC-5.8-04: BAND_ALREADY_PAIRED shows the mapped message', (tester) async {
    final fakeClient = FakeApiClient(postError: const ApiException(code: 'BAND_ALREADY_PAIRED', message: 'raw'));
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/connect-band-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Bluetooth Address'), 'C4:5B:BE:12:34:56');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Pair'));
    await tester.pumpAndSettle();

    expect(find.text('This Dependent already has a band paired.'), findsOneWidget);
  });
}
