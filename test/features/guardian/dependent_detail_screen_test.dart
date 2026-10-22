// Task 3.14 — TC-3.14-38..39. Like guardian_home_screen_test.dart, this
// screen had no test coverage before this task; scope here is kept to
// the new "Emergency settings" button and the screen's basic load, not a
// full backfill of every existing button's own navigation (those already
// have each destination screen's own direct tests).
//
// Extended for Task 4.6 (2026-10-22) — TC-4.6-21..22, for the new
// "Message" button, same "just this one new button" scope as the
// 3.14 extension above.
//
// Extended for Tasks 5.6/5.7/5.8/6.8 (2026-10-22) — TC-5.6-20..21,
// TC-5.7-12, TC-5.8-11, TC-6.8-17: the five new buttons (Medical
// records, Appointments, Vitals, Wearable band, Directory). Appointments
// gets its own id (TC-5.6-21) under 5.6's range rather than a sixth
// task id of its own, since `appointments_screen.dart` is grounded in
// the same `appointment_contract.md` family as the Medical records
// screen it sits beside on this screen. Each button's own id is the
// next free number after that screen's dedicated test file (e.g.
// `vitals_screen_test.dart`/`add_vital_reading_screen_test.dart` use
// up through TC-5.7-11, so this file's Vitals-button test is
// TC-5.7-12) — picked only after those files were written, to avoid
// colliding with their own numbering. Each test checks the button
// shows AND that tapping it navigates — one test per button, not two,
// to keep this already-large batch's test count proportional (same
// compacting judgement call as `activity_log_screen.dart`'s
// booking-detail sheet).
//
// Extended for Task 6.9 (2026-10-22) — TC-6.9-17..18, the new "Camera"
// button (one test for "shows", one for "navigates" — this button
// breaks the "one test per button" compacting above since it's the
// privacy-sensitive one of this batch, worth the extra test). Its ids
// sit in the Task 6.9 range (not a seventh/eighth button tacked onto
// the 5.6/5.7/5.8/6.8 range above) since `camera_screen_test.dart`'s
// own numbering starts at TC-6.9-04 after `camera_viewing_banner_test.
// dart` takes TC-6.9-01..03, and `camera_clips_screen_test.dart` runs
// through TC-6.9-16 — 17..18 are simply the next free numbers in that
// same task's range.
//
// Fix, 2026-10-22 (post-delivery, Talha's real `flutter test` run):
// inserting the new Camera button between Message and Medication
// schedule pushed every button from Medication schedule onward down
// one slot in this screen's lazy-building `ListView` — which flipped
// TC-5.6-20's "Medical Records" from inside the default test viewport
// to just outside it (`Found 0 widgets with text "Medical Records"`).
// Same lazy-build/viewport gotcha this file's own standing convention
// already names (see TC-6.8-17's comment below) — added
// `scrollUntilVisible` to TC-5.6-20 and, defensively, to TC-3.14-38/39
// (Emergency settings, now one slot closer to that same boundary)
// since `scrollUntilVisible` is a no-op when the target is already
// built, so this costs nothing if that one turns out to still be safely
// on-screen.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/guardian/dependent_summary.dart';
import 'package:humsafar_frontend/features/guardian/screens/dependent_detail_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

const _summary = DependentSummary(
  dependentId: 'dep-9',
  email: 'ammi@example.com',
  phone: '03001234567',
  myRole: 'primary',
  kycStatus: 'verified',
  accountActive: true,
);

List<GoRoute> _routes() => [
      GoRoute(
        path: '/guardian/dependent-detail',
        builder: (_, __) => const DependentDetailScreen(summary: _summary),
      ),
      GoRoute(path: '/guardian/emergency-settings', builder: (_, __) => stubScreen('EMERGENCY_SETTINGS_STUB')),
      GoRoute(path: '/messages/chat', builder: (_, __) => stubScreen('CHAT_STUB')),
      GoRoute(path: '/guardian/camera', builder: (_, __) => stubScreen('CAMERA_STUB')),
      GoRoute(path: '/records', builder: (_, __) => stubScreen('RECORDS_STUB')),
      GoRoute(path: '/appointments', builder: (_, __) => stubScreen('APPOINTMENTS_STUB')),
      GoRoute(path: '/vitals', builder: (_, __) => stubScreen('VITALS_STUB')),
      GoRoute(path: '/wearable', builder: (_, __) => stubScreen('WEARABLE_STUB')),
      GoRoute(path: '/directory', builder: (_, __) => stubScreen('DIRECTORY_STUB')),
    ];

void main() {
  testWidgets('TC-3.14-38: the screen loads and shows the Emergency settings button', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => <dynamic>[]);
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/dependent-detail',
      routes: _routes(),
    ));
    await tester.pumpAndSettle();

    // Defensive scroll — see the Task 6.9 fix note in this file's header
    // comment. No-op if already on-screen.
    await tester.scrollUntilVisible(find.text('Emergency settings'), 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Emergency settings'), findsOneWidget);
  });

  testWidgets('TC-3.14-39: tapping Emergency settings opens that screen', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => <dynamic>[]);
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/dependent-detail',
      routes: _routes(),
    ));
    await tester.pumpAndSettle();

    // Defensive scroll — see the Task 6.9 fix note in this file's header
    // comment. No-op if already on-screen.
    await tester.scrollUntilVisible(find.text('Emergency settings'), 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Emergency settings'));
    await tester.pumpAndSettle();

    expect(find.text('EMERGENCY_SETTINGS_STUB'), findsOneWidget);
  });

  testWidgets('TC-4.6-21: the screen shows a Message button', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => <dynamic>[]);
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/dependent-detail',
      routes: _routes(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Message'), findsOneWidget);
  });

  testWidgets('TC-4.6-22: tapping Message opens the chat with this Dependent as the peer', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => <dynamic>[]);
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/dependent-detail',
      routes: _routes(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();

    expect(find.text('CHAT_STUB'), findsOneWidget);
  });

  testWidgets('TC-6.9-17: the screen shows a Camera button', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => <dynamic>[]);
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/dependent-detail',
      routes: _routes(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Camera'), findsOneWidget);
  });

  testWidgets('TC-6.9-18: tapping Camera opens the camera screen for this Dependent', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => <dynamic>[]);
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/dependent-detail',
      routes: _routes(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Camera'));
    await tester.pumpAndSettle();

    expect(find.text('CAMERA_STUB'), findsOneWidget);
  });

  testWidgets('TC-5.6-20: Medical records shows and navigates to /records', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => <dynamic>[]);
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/dependent-detail',
      routes: _routes(),
    ));
    await tester.pumpAndSettle();

    // Fix, 2026-10-22: see the Task 6.9 fix note in this file's header
    // comment — the new Camera button pushed this button just past the
    // default test viewport.
    await tester.scrollUntilVisible(find.text('Medical Records'), 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Medical Records'), findsOneWidget);
    await tester.tap(find.text('Medical Records'));
    await tester.pumpAndSettle();

    expect(find.text('RECORDS_STUB'), findsOneWidget);
  });

  testWidgets('TC-5.6-21: Appointments shows and navigates to /appointments', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => <dynamic>[]);
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/dependent-detail',
      routes: _routes(),
    ));
    await tester.pumpAndSettle();

    // Same lazy-build/viewport reasoning as TC-6.8-17's Directory
    // scroll below — Appointments sits past Medical Records in this
    // screen's ~12-button ListView, outside the default test viewport.
    await tester.scrollUntilVisible(find.text('Appointments'), 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Appointments'), findsOneWidget);
    await tester.tap(find.text('Appointments'));
    await tester.pumpAndSettle();

    expect(find.text('APPOINTMENTS_STUB'), findsOneWidget);
  });

  testWidgets('TC-5.7-12: Vitals shows and navigates to /vitals', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => <dynamic>[]);
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/dependent-detail',
      routes: _routes(),
    ));
    await tester.pumpAndSettle();

    // Same scroll reasoning as TC-5.6-21's Appointments above.
    await tester.scrollUntilVisible(find.text('Vitals'), 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Vitals'), findsOneWidget);
    await tester.tap(find.text('Vitals'));
    await tester.pumpAndSettle();

    expect(find.text('VITALS_STUB'), findsOneWidget);
  });

  testWidgets('TC-5.8-11: Wearable band shows and navigates to /wearable', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => <dynamic>[]);
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/dependent-detail',
      routes: _routes(),
    ));
    await tester.pumpAndSettle();

    // Same scroll reasoning as TC-5.6-21's Appointments above.
    await tester.scrollUntilVisible(find.text('Wearable Band'), 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Wearable Band'), findsOneWidget);
    await tester.tap(find.text('Wearable Band'));
    await tester.pumpAndSettle();

    expect(find.text('WEARABLE_STUB'), findsOneWidget);
  });

  testWidgets('TC-6.8-17: Directory & Services shows and navigates to /directory', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => <dynamic>[]);
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/dependent-detail',
      routes: _routes(),
    ));
    await tester.pumpAndSettle();

    // "Directory & Services" is the last of ~12 stacked buttons in this
    // screen's plain ListView, which only builds items inside its
    // viewport — it needs to be scrolled into the tree before `find`
    // can see it at all (same lazy-build reasoning as
    // `my_band_screen_test.dart`'s Unpair/Generate Demo Data scrolls).
    await tester.scrollUntilVisible(find.text('Directory & Services'), 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Directory & Services'), findsOneWidget);
    await tester.tap(find.text('Directory & Services'));
    await tester.pumpAndSettle();

    expect(find.text('DIRECTORY_STUB'), findsOneWidget);
  });
}
