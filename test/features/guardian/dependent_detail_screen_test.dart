// Task 3.14 — TC-3.14-38..39. Like guardian_home_screen_test.dart, this
// screen had no test coverage before this task; scope here is kept to
// the new "Emergency settings" button and the screen's basic load, not a
// full backfill of every existing button's own navigation (those already
// have each destination screen's own direct tests).

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

    await tester.tap(find.text('Emergency settings'));
    await tester.pumpAndSettle();

    expect(find.text('EMERGENCY_SETTINGS_STUB'), findsOneWidget);
  });
}
