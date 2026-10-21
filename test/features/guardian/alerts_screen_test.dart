// Task 3.14 — TC-3.14-04..10.

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/features/guardian/screens/alerts_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

const _panicItem = {
  'notification_id': 'n-panic',
  'type': 'panic',
  'priority': 'critical',
  'title': 'Panic alert',
  'body': 'Test Dependent pressed panic.',
  'dependent_id': 'dep-9',
  'event_id': 'ev-1',
  'data': {'tier': 'primary', 'event_id': 'ev-1'},
  'sent_at': '2026-10-21T09:42:00Z',
  'acknowledged_at': null,
  'is_acknowledged': false,
};

const _missedDoseItem = {
  'notification_id': 'n-dose',
  'type': 'missed_dose',
  'priority': 'critical',
  'title': 'Missed medication',
  'body': 'Test Dependent has not taken Metformin (500 mg).',
  'dependent_id': 'dep-9',
  'event_id': 'ev-2',
  'data': {'tier': 'secondary', 'confirmation_id': 'conf-1', 'drug_name': 'Metformin', 'dosage': '500 mg'},
  'sent_at': '2026-10-21T14:00:00Z',
  'acknowledged_at': null,
  'is_acknowledged': false,
};

const _seenItem = {
  'notification_id': 'n-seen',
  'type': 'low_battery',
  'priority': 'critical',
  'title': 'Low battery',
  'body': 'Battery is low.',
  'dependent_id': 'dep-9',
  'event_id': 'ev-3',
  'data': <String, dynamic>{},
  'sent_at': '2026-10-20T08:00:00Z',
  'acknowledged_at': '2026-10-20T08:05:00Z',
  'is_acknowledged': true,
};

List<GoRoute> _routes() => [
      GoRoute(path: '/guardian/alerts', builder: (_, __) => const AlertsScreen()),
      GoRoute(
        path: '/guardian/missed-dose',
        builder: (_, __) => stubScreen('MISSED_DOSE_STUB'),
      ),
    ];

void main() {
  testWidgets('TC-3.14-04: Open tab shows unacknowledged items with the count in the tab label', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {
        'items': [_panicItem, _missedDoseItem, _seenItem],
        'unacknowledged_critical': 2,
        'next_before': null,
      },
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/guardian/alerts', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('Open (2)'), findsOneWidget);
    expect(find.text('Panic alert'), findsOneWidget);
    expect(find.text('Missed dose'), findsOneWidget);
    expect(find.text('Low battery'), findsNothing); // that one's acknowledged, so it's on Seen
  });

  testWidgets('TC-3.14-05: tier badge shows "Level 2 · Secondary" for data.tier secondary', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {
        'items': [_missedDoseItem],
        'unacknowledged_critical': 1,
      },
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/guardian/alerts', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('Level 2 · Secondary'), findsOneWidget);
  });

  testWidgets('TC-3.14-06: Seen tab shows acknowledged items only, Open tab empty state', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'items': [_seenItem]});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/guardian/alerts', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('No open alerts.'), findsOneWidget);
    await tester.tap(find.text('Seen'));
    await tester.pumpAndSettle();
    expect(find.text('Low battery'), findsOneWidget);
  });

  testWidgets('TC-3.14-07: "I\'ve seen it" on a missed_dose row acknowledges and opens Missed dose', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'items': [_missedDoseItem]},
      postHandler: (_) => {'notification_id': 'n-dose', 'is_acknowledged': true},
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/guardian/alerts', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.text("I've seen it"));
    await tester.pumpAndSettle();

    expect(fakeClient.postCalls, 1);
    expect(fakeClient.lastPostPath, '/notifications/n-dose/acknowledge');
    expect(find.text('MISSED_DOSE_STUB'), findsOneWidget);
  });

  testWidgets('TC-3.14-08: "I\'ve seen it" on a panic row acknowledges but does not navigate', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'items': [_panicItem]},
      postHandler: (_) => {'is_acknowledged': true},
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/guardian/alerts', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.text("I've seen it"));
    await tester.pumpAndSettle();

    expect(fakeClient.lastPostPath, '/notifications/n-panic/acknowledge');
    expect(find.text('Alerts'), findsOneWidget); // still on AlertsScreen
  });

  testWidgets('TC-3.14-09: a failed acknowledge shows a snackbar and leaves the item on Open', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (_) => {'items': [_panicItem]},
      postError: const ApiException(code: 'unexpected_error', message: 'Network error'),
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/guardian/alerts', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.text("I've seen it"));
    await tester.pumpAndSettle();

    expect(find.text('Network error'), findsOneWidget);
    expect(find.text('Panic alert'), findsOneWidget); // still there
  });

  testWidgets('TC-3.14-10: a load failure shows Retry, which reloads successfully', (tester) async {
    var shouldFail = true;
    final fakeClient = FakeApiClient(
      getHandler: (_) {
        if (shouldFail) {
          shouldFail = false;
          throw const ApiException(code: 'unexpected_error', message: "Couldn't load alerts.");
        }
        return {'items': [_panicItem]};
      },
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/guardian/alerts', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load alerts."), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Panic alert'), findsOneWidget);
  });
}
