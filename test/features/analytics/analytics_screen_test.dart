// Task 7.3 — TC-7.3-01..09. Grounded in `analytics_contract.md`'s written
// summary (see `AnalyticsScreen`'s own doc comment for the full assumed
// response shape and the named field-name caveat). Unlike almost every
// other permission-gated screen in this app, `GET /dependents/{id}/
// analytics` doesn't throw `MODULE_ACCESS_DENIED` for a part the caller
// lacks — the written summary says that part just comes back `null` in
// an otherwise-200 response — so the "no permission" tests below feed a
// `null` section through `getHandler`, not an `ApiException`.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/features/analytics/screens/analytics_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

const _dependentId = 'dep-42';

Map<String, dynamic> _fullAnalyticsBody() => {
      'days': 30,
      'adherence': {
        'rate': 0.92,
        'taken': 46,
        'missed': 4,
        'waiting': 2,
        'streak_days': 5,
        'change_vs_previous_period': 0.03,
        'per_day': [
          {'date': '2026-09-23', 'taken': 2, 'missed': 0, 'waiting': 0},
          {'date': '2026-09-24', 'taken': 1, 'missed': 1, 'waiting': 0},
        ],
        'per_medicine': [
          {'medicine_name': 'Metformin', 'rate': 0.95, 'taken': 19, 'missed': 1},
        ],
      },
      'vitals': {
        'metrics': {
          'blood_pressure': {
            'count': 4,
            'min': {'value': 110, 'diastolic': 70, 'unit': 'mmHg'},
            'max': {'value': 140, 'diastolic': 90, 'unit': 'mmHg'},
            'average': {'value': 122, 'diastolic': 78, 'unit': 'mmHg'},
            'latest': {'value': 118, 'diastolic': 76, 'unit': 'mmHg'},
            'trend': 'steady',
            'per_day': [
              {'date': '2026-09-23', 'value': 120, 'diastolic': 80},
              {'date': '2026-09-24', 'value': 118, 'diastolic': 76},
            ],
          },
          'heart_rate': {
            'count': 10,
            'min': {'value': 60, 'unit': 'bpm'},
            'max': {'value': 95, 'unit': 'bpm'},
            'average': {'value': 74, 'unit': 'bpm'},
            'latest': {'value': 72, 'unit': 'bpm'},
            'trend': 'rising',
            'per_day': [
              {'date': '2026-09-23', 'value': 70},
              {'date': '2026-09-24', 'value': 74},
            ],
          },
        },
      },
    };

List<GoRoute> _routes() => [
      GoRoute(
        path: '/guardian/analytics-under-test',
        builder: (_, __) => const AnalyticsScreen(dependentId: _dependentId, dependentLabel: 'Ammi'),
      ),
    ];

void main() {
  testWidgets('TC-7.3-01: loads and shows the adherence rate and vitals trend for the default metric', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => _fullAnalyticsBody());
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/analytics-under-test',
      routes: _routes(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Adherence rate: 92%'), findsOneWidget);
    expect(find.text('Taken: 46'), findsOneWidget);
    expect(find.text('Missed: 4'), findsOneWidget);
    // Default selected vitals metric is Blood Pressure.
    expect(find.text('Min: 110/70 mmHg'), findsOneWidget);
    expect(find.text('Latest: 118/76 mmHg'), findsOneWidget);
    expect(find.text('Trend: Steady'), findsOneWidget);
  });

  testWidgets('TC-7.3-02: requests days=30 by default', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => _fullAnalyticsBody());
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/analytics-under-test',
      routes: _routes(),
    ));
    await tester.pumpAndSettle();

    expect(fakeClient.lastGetPath, '/dependents/$_dependentId/analytics');
    expect(fakeClient.lastGetQueryParameters?['days'], 30);
  });

  testWidgets('TC-7.3-03: tapping the "7 days" chip re-fetches with days=7', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => _fullAnalyticsBody());
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/analytics-under-test',
      routes: _routes(),
    ));
    await tester.pumpAndSettle();

    final callsBefore = fakeClient.getCalls;
    await tester.tap(find.text('7 days'));
    await tester.pumpAndSettle();

    expect(fakeClient.getCalls, callsBefore + 1);
    expect(fakeClient.lastGetQueryParameters?['days'], 7);
  });

  testWidgets('TC-7.3-04: tapping a vitals metric chip switches the detail shown', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => _fullAnalyticsBody());
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/analytics-under-test',
      routes: _routes(),
    ));
    await tester.pumpAndSettle();

    // The adherence section (with its chart) pushes the vitals metric
    // chips below the default test viewport — same lazy-ListView gotcha
    // as elsewhere in this app. scrollUntilVisible is a no-op if it's
    // already on-screen.
    await tester.scrollUntilVisible(find.text('Heart Rate'), 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Heart Rate'));
    await tester.pumpAndSettle();

    expect(find.text('Latest: 72 bpm'), findsOneWidget);
    expect(find.text('Trend: Rising'), findsOneWidget);
    // Blood pressure's detail is no longer shown.
    expect(find.text('Latest: 118/76 mmHg'), findsNothing);
  });

  testWidgets('TC-7.3-05: a null adherence section shows the access-denied message, not a crash', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) {
      final body = _fullAnalyticsBody();
      body['adherence'] = null;
      return body;
    });
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/analytics-under-test',
      routes: _routes(),
    ));
    await tester.pumpAndSettle();

    expect(find.text("You don't have permission to view medication adherence for this Dependent."), findsOneWidget);
    expect(find.text('Taken: 46'), findsNothing);
  });

  testWidgets('TC-7.3-06: a null vitals section shows the access-denied message, not a crash', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) {
      final body = _fullAnalyticsBody();
      body['vitals'] = null;
      return body;
    });
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/analytics-under-test',
      routes: _routes(),
    ));
    await tester.pumpAndSettle();

    expect(find.text("You don't have permission to view vitals trends for this Dependent."), findsOneWidget);
  });

  testWidgets('TC-7.3-07: empty per_day arrays show the "no data yet" messages instead of a broken chart', (tester) async {
    final fakeClient = FakeApiClient(
        getHandler: (_) => {
              'adherence': {
                'rate': 0.0,
                'taken': 0,
                'missed': 0,
                'waiting': 0,
                'streak_days': 0,
                'per_day': <Map<String, dynamic>>[],
                'per_medicine': <Map<String, dynamic>>[],
              },
              'vitals': {
                'metrics': {
                  'blood_pressure': {'count': 0, 'per_day': <Map<String, dynamic>>[]},
                },
              },
            });
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/analytics-under-test',
      routes: _routes(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('No medication data yet for this period.'), findsOneWidget);
    expect(find.text('No vitals data yet for this period.'), findsOneWidget);
  });

  testWidgets('TC-7.3-08: a load failure shows the error and Retry reloads', (tester) async {
    final fakeClient = FakeApiClient(getError: const ApiException(code: 'UNEXPECTED', message: 'Something went wrong.'));
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/analytics-under-test',
      routes: _routes(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('TC-7.3-09: blood pressure shows the systolic-only chart note', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => _fullAnalyticsBody());
    await tester.pumpWidget(wrapWithRouter(
      fakeClient: fakeClient,
      initialLocation: '/guardian/analytics-under-test',
      routes: _routes(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Chart shows the systolic (top) number only.'), findsOneWidget);
  });
}
