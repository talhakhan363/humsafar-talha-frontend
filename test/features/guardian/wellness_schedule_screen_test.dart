import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/guardian/dependent_summary.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/features/guardian/screens/wellness_schedule_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

/// TC-3.15-12..19 — Task 3.15's Guardian-side Wellness check schedule
/// screen. See medication_schedule_screen_test.dart (TC-3.15-03..11)
/// for the other half of this task and the shared permission-handling
/// reasoning.
void main() {
  const primarySummary = DependentSummary(
    dependentId: 'dep-1',
    email: 'dep@example.com',
    phone: '03001234567',
    myRole: 'primary',
    kycStatus: 'verified',
    accountActive: true,
  );
  const secondarySummary = DependentSummary(
    dependentId: 'dep-1',
    email: 'dep@example.com',
    phone: '03001234567',
    myRole: 'secondary',
    kycStatus: 'verified',
    accountActive: true,
  );

  final morningCheck = {
    'wc_id': 'wc-1',
    'time': '08:00',
    'grace_period_min': 30,
    'active': true,
  };

  Widget screenFor(DependentSummary summary) => WellnessScheduleScreen(summary: summary);

  List<GoRoute> routesFor(Widget screen) =>
      [GoRoute(path: '/guardian/wellness-schedule-under-test', builder: (context, state) => screen)];

  testWidgets('TC-3.15-12: an empty schedule (Primary) offers the default-schedule shortcut', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': [], 'default_grace_period_min': 30});

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/wellness-schedule-under-test',
      routes: routesFor(screenFor(primarySummary)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('No wellness check times scheduled yet.'), findsOneWidget);
    expect(find.text('Use default schedule (8am, 2pm, 8pm)'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.15-13: tapping the default-schedule shortcut posts to default-schedule and refreshes',
      (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'items': [], 'default_grace_period_min': 30},
      postHandler: (_) => <String, dynamic>{},
    );

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/wellness-schedule-under-test',
      routes: routesFor(screenFor(primarySummary)),
    ));
    await tester.pumpAndSettle();
    expect(fakeClient.getCalls, 1);

    await tester.tap(find.text('Use default schedule (8am, 2pm, 8pm)'));
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, 1);
    expect(fakeClient.lastPostPath, '/dependents/dep-1/wellness-checks/default-schedule');
    expect(find.text('Saved.'), findsOneWidget);
    expect(fakeClient.getCalls, 2);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.15-14: a failed default-schedule call shows the raw server message (no mapping to apply)',
      (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'items': [], 'default_grace_period_min': 30},
      postError: const ApiException(code: 'unexpected_error', message: 'Something odd happened.'),
    );

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/wellness-schedule-under-test',
      routes: routesFor(screenFor(primarySummary)),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Use default schedule (8am, 2pm, 8pm)'));
    await tester.pumpAndSettle();

    expect(find.text('Something odd happened.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.15-15: a Secondary without emergency_alerts sees a read-only screen, no shortcut either',
      (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (path) => path.contains('permissions/me')
          ? {'guardian_role': 'secondary', 'modules': {'emergency_alerts': false}}
          : {'items': [morningCheck], 'default_grace_period_min': 30},
    );

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/wellness-schedule-under-test',
      routes: routesFor(screenFor(secondarySummary)),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text("You don't have permission to manage wellness checks. Ask the Primary Guardian."),
        findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.15-16: a Secondary WITH emergency_alerts can add and toggle', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (path) => path.contains('permissions/me')
          ? {'guardian_role': 'secondary', 'modules': {'emergency_alerts': true}}
          : {'items': [morningCheck], 'default_grace_period_min': 30},
    );

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/wellness-schedule-under-test',
      routes: routesFor(screenFor(secondarySummary)),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text("You don't have permission to manage wellness checks. Ask the Primary Guardian."), findsNothing);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNotNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.15-17: toggling a check off PUTs active:false', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'items': [Map<String, dynamic>.from(morningCheck)], 'default_grace_period_min': 30},
      putHandler: (_) => <String, dynamic>{},
    );

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/wellness-schedule-under-test',
      routes: routesFor(screenFor(primarySummary)),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(fakeClient.putCalls, 1);
    expect(fakeClient.lastPutPath, '/dependents/dep-1/wellness-checks/wc-1');
    expect(fakeClient.lastPutData, {'active': false});
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.15-18: Add form — WELLNESS_LIMIT_REACHED shows the mapped message, not the generic fallback',
      (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'items': [], 'default_grace_period_min': 30},
      postError: const ApiException(code: 'WELLNESS_LIMIT_REACHED', message: 'raw message should not show'),
    );

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/wellness-schedule-under-test',
      routes: routesFor(screenFor(primarySummary)),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('You can have at most 3 wellness check times.'), findsOneWidget);
    expect(find.text('raw message should not show'), findsNothing);
    expect(find.text("Couldn't save. Try again."), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('TC-3.15-19: Add form — a valid new time POSTs the right body and refreshes the list', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'items': [], 'default_grace_period_min': 30},
      postHandler: (_) => <String, dynamic>{},
    );

    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/wellness-schedule-under-test',
      routes: routesFor(screenFor(primarySummary)),
    ));
    await tester.pumpAndSettle();
    expect(fakeClient.getCalls, 1);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, 1);
    expect(fakeClient.lastPostPath, '/dependents/dep-1/wellness-checks');
    expect(fakeClient.lastPostData, {'times': ['08:00'], 'grace_period_min': 30});
    expect(find.text('Saved.'), findsOneWidget);
    expect(fakeClient.getCalls, 2);

    await tester.pumpWidget(const SizedBox());
  });
}
