// Task 6.9 (FR-K1.3 privacy indicator) — TC-6.9-01..03. The Dependent-
// side "a Guardian is watching your camera" banner. Polls
// `GET /dependents/{id}/camera/viewing` every 15s and renders nothing
// when nobody is watching — see camera_viewing_banner.dart's own doc
// comment for the named field-name caveat this is built against.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/features/dependent/widgets/camera_viewing_banner.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

List<GoRoute> _routes() => [
      GoRoute(
        path: '/banner-under-test',
        builder: (_, __) => const Scaffold(body: CameraViewingBanner(dependentId: 'dep-1')),
      ),
    ];

void main() {
  testWidgets('TC-6.9-01: hidden when nobody is watching', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'is_being_viewed': false});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/banner-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('A Guardian is watching your camera right now'), findsNothing);

    // Dispose before the test ends so the 15s poll Timer.periodic
    // doesn't leak past this test (same reasoning as
    // live_map_screen_test.dart's own teardown).
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-6.9-02: shows the banner with no count suffix when exactly one Guardian is watching', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'is_being_viewed': true, 'viewer_count': 1});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/banner-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('A Guardian is watching your camera right now'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-6.9-03: shows the viewer count when more than one is watching, and re-polls after 15s', (tester) async {
    var isBeingViewed = true;
    final fakeClient = FakeApiClient(getHandler: (_) => {'is_being_viewed': isBeingViewed, 'viewer_count': 3});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/banner-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.textContaining('3 watching now'), findsOneWidget);

    // Flip the backend's answer and let the next 15s poll pick it up.
    isBeingViewed = false;
    await tester.pump(const Duration(seconds: 15));
    await tester.pumpAndSettle();

    expect(find.text('A Guardian is watching your camera right now'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });
}
