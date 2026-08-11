import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'accessibility_mode.dart';

/// Task 1.9 — holds which theme is active right now.
///
/// This is deliberately just in-memory state for now (it resets on app
/// restart). Persisting the choice — e.g. with `shared_preferences` — is a
/// natural follow-up once that dependency is actually needed somewhere
/// else too; not pulling it in just for this one flag.
class AccessibilityModeNotifier extends Notifier<AccessibilityMode> {
  @override
  AccessibilityMode build() => AccessibilityMode.standard;

  void toggle() {
    state = state == AccessibilityMode.standard
        ? AccessibilityMode.highContrast
        : AccessibilityMode.standard;
  }
}

final accessibilityModeProvider =
    NotifierProvider<AccessibilityModeNotifier, AccessibilityMode>(
  AccessibilityModeNotifier.new,
);
