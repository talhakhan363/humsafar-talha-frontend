import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humsafar_frontend/features/dependent/widgets/panic_hold_button.dart';

import '../../support/gesture_test_helpers.dart';

/// TC-3.11-01..03 — widget tests for the hold-to-confirm gesture timing
/// (Task 3.11). Pure widget: no ApiClient, no l10n (label/subtitle are
/// passed in already resolved, same convention as PanicButton /
/// SafetyActionButton), no device. `holdDuration` is overridden to a few
/// milliseconds so the test doesn't need to wait out the real 2-second
/// default.
///
/// Uses `startHoldGesture` (test/support/gesture_test_helpers.dart)
/// instead of calling `tester.startGesture` directly — that helper
/// bakes in the baseline `pump()` this kind of test needs; see its doc
/// comment for why.
void main() {
  testWidgets('TC-3.11-01: holding for the full duration fires onHoldComplete once', (tester) async {
    var completeCount = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PanicHoldButton(
          label: 'HOLD',
          subtitle: 'to send help',
          holdDuration: const Duration(milliseconds: 100),
          onHoldComplete: () => completeCount++,
        ),
      ),
    ));

    final gesture = await startHoldGesture(tester, find.byType(PanicHoldButton));
    await tester.pump(const Duration(milliseconds: 120));
    expect(completeCount, 1);

    await gesture.up();
    await tester.pump();
  });

  testWidgets('TC-3.11-02: releasing early cancels the hold — onHoldComplete never fires', (tester) async {
    var completeCount = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PanicHoldButton(
          label: 'HOLD',
          subtitle: 'to send help',
          holdDuration: const Duration(milliseconds: 100),
          onHoldComplete: () => completeCount++,
        ),
      ),
    ));

    final gesture = await startHoldGesture(tester, find.byType(PanicHoldButton));
    await tester.pump(const Duration(milliseconds: 30));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 200));

    expect(completeCount, 0);
  });

  testWidgets('TC-3.11-03: enabled=false ignores a press entirely', (tester) async {
    var completeCount = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PanicHoldButton(
          label: 'HOLD',
          subtitle: 'to send help',
          holdDuration: const Duration(milliseconds: 50),
          enabled: false,
          onHoldComplete: () => completeCount++,
        ),
      ),
    ));

    final gesture = await startHoldGesture(tester, find.byType(PanicHoldButton));
    await tester.pump(const Duration(milliseconds: 80));
    await gesture.up();

    expect(completeCount, 0);
  });
}
