// Task 3.14 — TC-3.14-28..32. Uses the harness's default
// `kTestDependentUser` (userId 'dep-1'), since AlarmScreen always acts
// for the current signed-in Dependent (`/dependents/dep-1/alarm[/stop]`).

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/core/network/api_exception.dart';
import 'package:humsafar_frontend/features/dependent/screens/alarm_screen.dart';

import '../../support/fake_api_client.dart';
import '../../support/widget_test_harness.dart';

List<GoRoute> _routes() => [
      GoRoute(path: '/dependent/alarm', builder: (_, __) => const AlarmScreen()),
      GoRoute(path: '/dependent', builder: (_, __) => stubScreen('DEPENDENT_HOME_STUB')),
    ];

void main() {
  testWidgets('TC-3.14-28: an active alarm shows the "looking for you" screen with a countdown', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (path) {
      if (path == '/dependents/dep-1/alarm') {
        return {
          'active': true,
          'alarm': {
            'alarm_id': 'a-1',
            'status': 'active',
            'expires_at': DateTime.now().add(const Duration(seconds: 48)).toUtc().toIso8601String(),
          },
        };
      }
      return <String, dynamic>{};
    });
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/dependent/alarm', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('Your Guardian is looking for you'), findsOneWidget);
    expect(find.text('Stop alarm'), findsOneWidget);
  });

  testWidgets('TC-3.14-29: Stop alarm posts /alarm/stop and leaves the screen', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (path) {
        if (path == '/dependents/dep-1/alarm') {
          return {
            'active': true,
            'alarm': {'alarm_id': 'a-1', 'status': 'active', 'expires_at': DateTime.now().add(const Duration(minutes: 1)).toUtc().toIso8601String()},
          };
        }
        return <String, dynamic>{};
      },
      postHandler: (_) => {'alarm_id': 'a-1', 'status': 'stopped'},
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/dependent/alarm', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stop alarm'));
    await tester.pumpAndSettle();

    expect(fakeClient.lastPostPath, '/dependents/dep-1/alarm/stop');
    expect(find.text('DEPENDENT_HOME_STUB'), findsOneWidget);
  });

  testWidgets('TC-3.14-30: no active alarm shows the empty state with a way back', (tester) async {
    final fakeClient = FakeApiClient(getHandler: (_) => {'active': false, 'alarm': null});
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/dependent/alarm', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text('No alarm is sounding right now.'), findsOneWidget);
    await tester.tap(find.text('Go back'));
    await tester.pumpAndSettle();
    expect(find.text('DEPENDENT_HOME_STUB'), findsOneWidget);
  });

  testWidgets('TC-3.14-31: a load failure shows Retry', (tester) async {
    final fakeClient = FakeApiClient(
      getError: const ApiException(code: 'unexpected_error', message: "Couldn't check the alarm."),
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/dependent/alarm', routes: _routes()));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't check the alarm."), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('TC-3.14-32: a failed Stop shows a snackbar and stays on the screen', (tester) async {
    final fakeClient = FakeApiClient(
      getHandler: (path) => {
        'active': true,
        'alarm': {'alarm_id': 'a-1', 'status': 'active', 'expires_at': DateTime.now().add(const Duration(minutes: 1)).toUtc().toIso8601String()},
      },
      postError: const ApiException(code: 'NO_ACTIVE_ALARM', message: 'raw'),
    );
    await tester.pumpWidget(wrapWithRouter(fakeClient: fakeClient, initialLocation: '/dependent/alarm', routes: _routes()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stop alarm'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't stop the alarm. Try again."), findsOneWidget);
    expect(find.text('Your Guardian is looking for you'), findsOneWidget);
  });
}
