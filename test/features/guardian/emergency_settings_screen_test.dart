// Task 3.14 — TC-3.14-20..27.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/guardian/dependent_summary.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/features/guardian/screens/emergency_settings_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

const _primarySummary = DependentSummary(
  dependentId: 'dep-9',
  email: 'ammi@example.com',
  phone: '03001234567',
  myRole: 'primary',
  kycStatus: 'verified',
  accountActive: true,
);

const _secondarySummary = DependentSummary(
  dependentId: 'dep-9',
  email: 'ammi@example.com',
  phone: '03001234567',
  myRole: 'secondary',
  kycStatus: 'verified',
  accountActive: true,
);

List<GoRoute> _routes(DependentSummary summary) => [
      GoRoute(path: '/guardian/emergency-settings', builder: (_, __) => EmergencySettingsScreen(summary: summary)),
    ];

void main() {
  testWidgets('TC-3.14-20: Primary with no active alarm sees "Ring alarm (60 s)"', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path == '/dependents/dep-9/alarm') return {'active': false, 'alarm': null};
      throw const ApiException(code: 'EMERGENCY_CONTACT_NOT_FOUND', message: '');
    });
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/emergency-settings',
      routes: _routes(_primarySummary),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Ring alarm (60 s)'), findsOneWidget);
    expect(find.text('Stop alarm'), findsNothing);
  });

  testWidgets('TC-3.14-21: tapping Ring alarm posts /alarm and flips to Stop alarm', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (path) {
        if (path == '/dependents/dep-9/alarm') return {'active': false, 'alarm': null};
        throw const ApiException(code: 'EMERGENCY_CONTACT_NOT_FOUND', message: '');
      },
      postHandler: (_) => {'alarm_id': 'a-1', 'status': 'active', 'already_active': false},
    );
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/emergency-settings',
      routes: _routes(_primarySummary),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ring alarm (60 s)'));
    await tester.pumpAndSettle();

    expect(fakeClient.lastPostPath, '/dependents/dep-9/alarm');
    expect(find.text('Stop alarm'), findsOneWidget);
  });

  testWidgets('TC-3.14-22: a Secondary never calls GET .../alarm and sees the Primary-only note', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path == '/dependents/dep-9/alarm') {
        fail('a Secondary must never call GET /dependents/{id}/alarm');
      }
      throw const ApiException(code: 'MODULE_ACCESS_DENIED', message: '');
    });
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/emergency-settings',
      routes: _routes(_secondarySummary),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Only the Primary Guardian can use the remote alarm and set the emergency contact.'), findsOneWidget);
    expect(find.text('Ring alarm (60 s)'), findsNothing);
  });

  testWidgets('TC-3.14-23: Primary sees an existing emergency contact with Save/Remove', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path == '/dependents/dep-9/alarm') return {'active': false, 'alarm': null};
      if (path == '/dependents/dep-9/emergency-contact') {
        return {'contact_id': 'c-1', 'name': 'Uncle Bilal', 'phone': '+923007654321'};
      }
      return <String, dynamic>{};
    });
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/emergency-settings',
      routes: _routes(_primarySummary),
    ));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Name'), findsOneWidget);
    expect(find.text('Uncle Bilal'), findsOneWidget);
    expect(find.text('Remove contact'), findsOneWidget);
  });

  testWidgets('TC-3.14-24: Primary with no contact set sees Save but not Remove', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path == '/dependents/dep-9/alarm') return {'active': false, 'alarm': null};
      throw const ApiException(code: 'EMERGENCY_CONTACT_NOT_FOUND', message: '');
    });
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/emergency-settings',
      routes: _routes(_primarySummary),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Save contact'), findsOneWidget);
    expect(find.text('Remove contact'), findsNothing);
  });

  testWidgets('TC-3.14-25: Secondary without emergency_alerts sees the denied note', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      throw const ApiException(code: 'MODULE_ACCESS_DENIED', message: 'denied');
    });
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/emergency-settings',
      routes: _routes(_secondarySummary),
    ));
    await tester.pumpAndSettle();

    expect(find.text('You can view this but only the Primary Guardian can change it.'), findsOneWidget);
  });

  testWidgets('TC-3.14-26: a 422 on Save shows the server\'s own validation message', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (path) {
        if (path == '/dependents/dep-9/alarm') return {'active': false, 'alarm': null};
        throw const ApiException(code: 'EMERGENCY_CONTACT_NOT_FOUND', message: '');
      },
      putError: const ApiException(code: 'VALIDATION_ERROR', message: 'Phone number is not valid.'),
    );
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/emergency-settings',
      routes: _routes(_primarySummary),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Aunt Sara');
    await tester.enterText(find.widgetWithText(TextField, 'Phone'), 'not-a-phone');
    await tester.tap(find.text('Save contact'));
    await tester.pumpAndSettle();

    expect(find.text('Phone number is not valid.'), findsOneWidget);
  });

  testWidgets('TC-3.14-27: Remove contact succeeds and clears the fields', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (path) {
        if (path == '/dependents/dep-9/alarm') return {'active': false, 'alarm': null};
        if (path == '/dependents/dep-9/emergency-contact') {
          return {'contact_id': 'c-1', 'name': 'Uncle Bilal', 'phone': '+923007654321'};
        }
        return <String, dynamic>{};
      },
      deleteHandler: (_) => <String, dynamic>{},
    );
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/emergency-settings',
      routes: _routes(_primarySummary),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove contact'));
    await tester.pumpAndSettle();

    expect(fakeClient.lastDeletePath, '/dependents/dep-9/emergency-contact');
    expect(find.text('Contact removed.'), findsOneWidget);
    expect(find.text('Remove contact'), findsNothing);
  });
}
