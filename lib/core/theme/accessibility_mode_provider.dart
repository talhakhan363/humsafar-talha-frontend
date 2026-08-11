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

  // Bug fix (2026-08-11): rapid repeated taps on the toggle button used to
  // fire multiple state changes before Material's ink-splash animation and
  // the Theme subtree rebuild from the PREVIOUS toggle had finished
  // settling (~300-400ms). Overlapping those caused an internal ink-feature
  // GlobalKey collision — that's the "GlobalKey was used multiple times"
  // crash. This ignores any toggle() call that arrives while a previous one
  // is still settling, so a burst of fast taps collapses into a single
  // real theme change instead of several overlapping ones.
  DateTime? _lastToggleAt;
  static const _debounce = Duration(milliseconds: 400);

  void toggle() {
    final now = DateTime.now();
    if (_lastToggleAt != null && now.difference(_lastToggleAt!) < _debounce) {
      return;
    }
    _lastToggleAt = now;
    state = state == AccessibilityMode.standard ? AccessibilityMode.highContrast : AccessibilityMode.standard;
  }
}

final accessibilityModeProvider = NotifierProvider<AccessibilityModeNotifier, AccessibilityMode>(
  AccessibilityModeNotifier.new,
);
