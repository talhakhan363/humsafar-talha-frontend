// Task 6.9 (FR-K1.3 privacy indicator) — TC-6.9-01..03. The Dependent-
// side "a Guardian is watching your camera" banner. Polls
// `GET /dependents/{id}/camera/viewing` every 15s and renders nothing
// when nobody is watching. Mocks updated 2026-10-22 to the real field
// names (`being_viewed`/`viewers` list) per the field-name fix in
// camera_viewing_banner.dart's own doc comment — see that fix for why.

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
    final fakeClient = FakeApiClient(getHandler: (_) => {'being_viewed': false, 'viewers': <Map<String, dynamic>>[]});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/banner-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('A Guardian is watching your camera right now'), findsNothing);

    // Dispose before the test ends so the 15s poll Timer.periodic
    // doesn't leak past this test (same reasoning as
    // live_map_screen_test.dart's own teardown).
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-6.9-02: shows the banner with no count suffix when exactly one Guardian is watching', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {
        'being_viewed': true,
        'viewers': [
          {'user_id': 'g-1', 'full_name': 'Abdullah', 'role': 'primary', 'since': '2026-10-22T10:00:00Z'},
        ],
      },
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/banner-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('A Guardian is watching your camera right now'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-6.9-03: shows the viewer count when more than one is watching, and re-polls after 15s', (tester) async {
    var isBeingViewed = true;
    final fakeClient = FakeApiClient(
      getHandler: (_) => {
        'being_viewed': isBeingViewed,
        'viewers': isBeingViewed
            ? [
                {'user_id': 'g-1', 'full_name': 'Abdullah', 'role': 'primary', 'since': '2026-10-22T10:00:00Z'},
                {'user_id': 'g-2', 'full_name': 'Sarim', 'role': 'secondary', 'since': '2026-10-22T10:01:00Z'},
                {'user_id': 'g-3', 'full_name': 'Talha', 'role': 'secondary', 'since': '2026-10-22T10:02:00Z'},
              ]
            : <Map<String, dynamic>>[],
      },
    );
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
