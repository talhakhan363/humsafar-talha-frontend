// Task 3.14 — TC-3.14-11..19.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/features/guardian/screens/missed_dose_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

const _dependentsList = [
  {
    'dependent_id': 'dep-9',
    'email': 'ammi@example.com',
    'phone': '03001234567',
    'my_role': 'primary',
    'kyc_status': 'verified',
    'account_active': true,
  },
];

Map<String, dynamic> _dose({String? tier = 'primary'}) => {
      'confirmation_id': 'conf-1',
      'schedule_id': 'sched-1',
      'drug_name': 'Metformin',
      'dosage': '500 mg',
      'scheduled_for': '2026-10-21T14:00:00Z',
      'status': 'missed',
      'confirmed_at': null,
      'window_ends_at': '2026-10-21T14:30:00Z',
      'open_alert_tier': tier,
    };

List<GoRoute> _routes({Future<bool> Function(Uri)? launchUrlOverride}) => [
      GoRoute(
        path: '/guardian/missed-dose',
        builder: (_, __) => MissedDoseScreen(
          confirmationId: 'conf-1',
          dependentId: 'dep-9',
          notificationId: 'notif-1',
          launchUrlOverride: launchUrlOverride,
        ),
      ),
    ];

void main() {
  testWidgets('TC-3.14-11: loads the dose + Dependent and shows the banner', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path == '/dependents/dep-9/medication-doses') return {'items': [_dose()]};
      if (path == '/guardians/me/dependents') return _dependentsList;
      return <String, dynamic>{};
    });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/guardian/missed-dose', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.textContaining('ammi@example.com'), findsWidgets);
    expect(find.textContaining('Metformin'), findsWidgets);
    expect(find.text('500 mg'), findsOneWidget);
    expect(find.text('You are told (Primary)'), findsOneWidget);
  });

  testWidgets('TC-3.14-12: a dose no longer in the list shows "already resolved"', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path == '/dependents/dep-9/medication-doses') return {'items': <dynamic>[]};
      if (path == '/guardians/me/dependents') return _dependentsList;
      return <String, dynamic>{};
    });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/guardian/missed-dose', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('This alert has already been resolved.'), findsOneWidget);
  });

  testWidgets('TC-3.14-13: "Give more time" posts extend + acknowledges the alert', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (path) {
        if (path == '/dependents/dep-9/medication-doses') return {'items': [_dose()]};
        if (path == '/guardians/me/dependents') return _dependentsList;
        return <String, dynamic>{};
      },
      postHandler: (_) => <String, dynamic>{},
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/guardian/missed-dose', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Give more time (+30 min)'));
    await tester.pumpAndSettle();

    expect(fakeClient.lastPostPath, '/notifications/notif-1/acknowledge');
    expect(find.text('Given 30 more minutes.'), findsOneWidget);
  });

  testWidgets('TC-3.14-14: "Tell other Guardians now" with notified > 0 shows the count', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (path) {
        if (path == '/dependents/dep-9/medication-doses') return {'items': [_dose()]};
        if (path == '/guardians/me/dependents') return _dependentsList;
        return <String, dynamic>{};
      },
      postHandler: (path) {
        if (path.endsWith('/escalate')) {
          return {'confirmation_id': 'conf-1', 'event_id': 'ev-1', 'tier': 'secondary', 'notified': 2};
        }
        return <String, dynamic>{};
      },
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/guardian/missed-dose', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tell other Guardians now'));
    await tester.pumpAndSettle();

    expect(find.text('2 Secondary Guardian(s) notified.'), findsOneWidget);
  });

  testWidgets('TC-3.14-15: "Tell other Guardians now" with notified == 0 shows the "no Secondary" message', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (path) {
        if (path == '/dependents/dep-9/medication-doses') return {'items': [_dose()]};
        if (path == '/guardians/me/dependents') return _dependentsList;
        return <String, dynamic>{};
      },
      postHandler: (path) {
        if (path.endsWith('/escalate')) {
          return {'confirmation_id': 'conf-1', 'event_id': 'ev-1', 'tier': 'secondary', 'notified': 0};
        }
        return <String, dynamic>{};
      },
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/guardian/missed-dose', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tell other Guardians now'));
    await tester.pumpAndSettle();

    expect(find.text('No Secondary Guardian can see alerts yet.'), findsOneWidget);
  });

  testWidgets('TC-3.14-16: ALREADY_ESCALATED maps to a clear message', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (path) {
        if (path == '/dependents/dep-9/medication-doses') return {'items': [_dose()]};
        if (path == '/guardians/me/dependents') return _dependentsList;
        return <String, dynamic>{};
      },
      postError: const ApiException(code: 'ALREADY_ESCALATED', message: 'raw server message'),
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/guardian/missed-dose', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tell other Guardians now'));
    await tester.pumpAndSettle();

    expect(find.text('Already told the other Guardians.'), findsOneWidget);
  });

  testWidgets('TC-3.14-17: "Tell other Guardians now" is disabled once the alert is already at Secondary', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path == '/dependents/dep-9/medication-doses') return {'items': [_dose(tier: 'secondary')]};
      if (path == '/guardians/me/dependents') return _dependentsList;
      return <String, dynamic>{};
    });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/guardian/missed-dose', routes: _routes()));
    await tester.pumpAndSettle();

    final button = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Tell other Guardians now'));
    expect(button.onPressed, isNull);
  });

  testWidgets('TC-3.14-18: tapping Call when the dialer can\'t be opened shows the call-failed snackbar', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path == '/dependents/dep-9/medication-doses') return {'items': [_dose()]};
      if (path == '/guardians/me/dependents') return _dependentsList;
      return <String, dynamic>{};
    });
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/missed-dose',
      routes: _routes(launchUrlOverride: (_) async => false),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Call ammi@example.com'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't start the call."), findsOneWidget);
  });

  testWidgets('TC-3.14-19: tapping Call with a dialer available opens it and acknowledges the alert', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (path) {
        if (path == '/dependents/dep-9/medication-doses') return {'items': [_dose()]};
        if (path == '/guardians/me/dependents') return _dependentsList;
        return <String, dynamic>{};
      },
      postHandler: (_) => <String, dynamic>{},
    );
    Uri? requestedUri;
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/missed-dose',
      routes: _routes(launchUrlOverride: (uri) async {
        requestedUri = uri;
        return true;
      }),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Call ammi@example.com'));
    await tester.pumpAndSettle();

    expect(requestedUri, Uri(scheme: 'tel', path: '03001234567'));
    expect(fakeClient.lastPostPath, '/notifications/notif-1/acknowledge');
    expect(find.text("Couldn't start the call."), findsNothing);
  });
}
