// Task 6.9 — TC-6.9-04..12. Guardian-side camera screen (UI-only slice:
// exercises the real pairing/watch-session calls, but doesn't render
// actual video — see camera_screen.dart's own doc comment for why).
// Mocks updated 2026-10-22 to the real field names (`paired` bool,
// `viewers_now` from the plain `/camera` endpoint rather than a
// viewer-count field on `/camera/stream`) per that file's field-name fix.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/features/camera/screens/camera_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

List<GoRoute> _routes() => [
      GoRoute(
        path: '/camera-under-test',
        builder: (_, __) => const CameraScreen(dependentId: 'dep-1', dependentLabel: 'Test Dependent'),
      ),
      GoRoute(path: '/guardian/camera/clips', builder: (_, __) => stubScreen('CLIPS_STUB')),
    ];

// Same reasoning as my_band_screen_test.dart's helpers — every button
// here is built with the `.icon(...)` factory constructor.
Finder _elevatedButtonWithText(String text) =>
    find.ancestor(of: find.text(text), matching: find.byWidgetPredicate((widget) => widget is ElevatedButton));

Finder _outlinedButtonWithText(String text) =>
    find.ancestor(of: find.text(text), matching: find.byWidgetPredicate((widget) => widget is OutlinedButton));

void main() {
  testWidgets('TC-6.9-04: not_paired shows the placeholder, no Start Watching button', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'paired': false});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/camera-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('No camera has been paired for this Dependent yet.'), findsOneWidget);
    expect(find.text('Start Watching'), findsNothing);
  });

  testWidgets('TC-6.9-05: a pairing-status load error shows the error and Retry', (tester) async {
    final fakeClient = FakeApiClient(getError: const ApiException(code: 'SERVER_ERROR', message: 'camera status unavailable'));
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/camera-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('camera status unavailable'), findsOneWidget);
    expect(_elevatedButtonWithText('Retry'), findsOneWidget);
  });

  testWidgets('TC-6.9-06: paired + Start Watching shows the watching placeholder and viewer count', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path.endsWith('/camera/stream')) return <String, dynamic>{};
      return {'paired': true, 'viewers_now': 2};
    });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/camera-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(_elevatedButtonWithText('Start Watching'));
    await tester.pumpAndSettle();

    expect(find.textContaining("Live video isn't wired up yet"), findsOneWidget);
    expect(find.text('2 watching now'), findsOneWidget);
    expect(_outlinedButtonWithText('Stop Watching'), findsOneWidget);

    // Dispose before the test ends so the 30s renew Timer.periodic
    // doesn't leak past this test (same reasoning as
    // live_map_screen_test.dart's own teardown).
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-6.9-07: Stop Watching DELETEs the session and returns to the start prompt', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path.endsWith('/camera/stream')) return <String, dynamic>{};
      return {'paired': true, 'viewers_now': 1};
    });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/camera-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(_elevatedButtonWithText('Start Watching'));
    await tester.pumpAndSettle();
    await tester.tap(_outlinedButtonWithText('Stop Watching'));
    await tester.pumpAndSettle();

    expect(fakeClient.deleteCalls, 1);
    expect(fakeClient.lastDeletePath, '/dependents/dep-1/camera/stream');
    expect(find.text('Start Watching'), findsOneWidget);
  });

  testWidgets('TC-6.9-08: CAMERA_NOT_PAIRED on start-watching shows the mapped message', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path.endsWith('/camera/stream')) throw const ApiException(code: 'CAMERA_NOT_PAIRED', message: 'raw');
      return {'paired': true};
    });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/camera-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(_elevatedButtonWithText('Start Watching'));
    await tester.pumpAndSettle();

    expect(find.text('No camera has been paired for this Dependent yet.'), findsOneWidget);
  });

  testWidgets('TC-6.9-09: CAMERA_OFFLINE on start-watching shows the mapped message', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path.endsWith('/camera/stream')) throw const ApiException(code: 'CAMERA_OFFLINE', message: 'raw');
      return {'paired': true};
    });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/camera-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(_elevatedButtonWithText('Start Watching'));
    await tester.pumpAndSettle();

    expect(find.text("The camera is paired but isn't reachable right now."), findsOneWidget);
  });

  testWidgets('TC-6.9-10: MODULE_ACCESS_DENIED on start-watching shows the mapped message', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path.endsWith('/camera/stream')) throw const ApiException(code: 'MODULE_ACCESS_DENIED', message: 'raw');
      return {'paired': true};
    });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/camera-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(_elevatedButtonWithText('Start Watching'));
    await tester.pumpAndSettle();

    expect(find.text("You don't have permission to view this camera."), findsOneWidget);
  });

  testWidgets('TC-6.9-11: MAX_VIEWERS_REACHED on start-watching shows the mapped message', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path.endsWith('/camera/stream')) throw const ApiException(code: 'MAX_VIEWERS_REACHED', message: 'raw');
      return {'paired': true};
    });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/camera-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(_elevatedButtonWithText('Start Watching'));
    await tester.pumpAndSettle();

    expect(find.text('Too many Guardians are already watching. Try again shortly.'), findsOneWidget);
  });

  testWidgets('TC-6.9-12: the Saved Clips icon navigates to the clips screen', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'paired': true});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/camera-under-test', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Saved Clips'));
    await tester.pumpAndSettle();

    expect(find.text('CLIPS_STUB'), findsOneWidget);
  });
}
