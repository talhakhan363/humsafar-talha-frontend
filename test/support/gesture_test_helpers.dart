// test/support/gesture_test_helpers.dart
//
// Flutter-testing gotcha: an AnimationController started synchronously
// from a raw pointer-event handler (outside the normal build/frame
// cycle) needs a bare `await tester.pump()` immediately after
// `tester.startGesture(...)` and before any duration-advancing
// `tester.pump(duration)`. Without it, that single duration-pump's own
// already-advanced timestamp becomes the controller's Ticker's internal
// t=0 baseline, so `elapsed` computes as ~0 relative to itself and the
// animation never appears to progress within that call — even though
// the gesture and the controller are both working correctly.
//
// This is exactly what caused TC-3.11-01/02/03/06/07 (Task 3.11) to
// fail identically before it was understood — see
// test_cases/TEST_CASE_LOG.md for the full writeup. Routing every
// hold-gesture test through this helper makes it structurally
// impossible to forget the baseline pump again.

import 'package:flutter_test/flutter_test.dart';

/// Starts a press-and-hold gesture at the center of [target] and
/// immediately locks in the correct t=0 baseline frame for any
/// AnimationController the press triggers. Always use this instead of
/// calling `tester.startGesture(...)` directly for a hold-to-confirm
/// style gesture; follow it with whatever duration-advancing
/// `tester.pump(duration)` calls the test needs.
Future<TestGesture> startHoldGesture(WidgetTester tester, Finder target) async {
  final gesture = await tester.startGesture(tester.getCenter(target));
  await tester.pump();
  return gesture;
}
