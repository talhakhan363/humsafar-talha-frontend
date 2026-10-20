import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humsafar_frontend/features/dependent/widgets/panic_hold_button.dart';

/// TC-3.11-01..03 — widget tests for the hold-to-confirm gesture timing
/// (Task 3.11). Pure widget: no ApiClient, no l10n (label/subtitle are
/// passed in already resolved, same convention as PanicButton /
/// SafetyActionButton), no device. `holdDuration` is overridden to a few
/// milliseconds so the test doesn't need to wait out the real 2-second
/// default.
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

    final gesture = await tester.startGesture(tester.getCenter(find.byType(PanicHoldButton)));
    // A bare pump() first establishes the AnimationController's t=0
    // baseline frame; without it, a single pump(duration) right after
    // forward() treats that already-advanced timestamp AS t=0, so the
    // controller reads as having made no progress at all. This was the
    // real bug behind TC-3.11-01/02/03/06/07 failing identically — not
    // the gesture type (GestureDetector vs Listener), which was a red
    // herring.
    await tester.pump();
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

    final gesture = await tester.startGesture(tester.getCenter(find.byType(PanicHoldButton)));
    await tester.pump(); // baseline frame — see TC-3.11-01's comment
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

    final gesture = await tester.startGesture(tester.getCenter(find.byType(PanicHoldButton)));
    await tester.pump(); // baseline frame — see TC-3.11-01's comment
    await tester.pump(const Duration(milliseconds: 80));
    await gesture.up();

    expect(completeCount, 0);
  });
}
