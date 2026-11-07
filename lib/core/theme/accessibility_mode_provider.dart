import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility_mode.dart';

/// Task 1.9 — holds which theme is active right now.
///
/// Bug fix (N-02, QA 3.16 Accessibility Results v1.0, B-02): this used to
/// be in-memory only, so the large-text/high-contrast toggle silently
/// reset to standard on every app restart — exactly the kind of setting
/// someone turns on once because they need it, not every single time they
/// open the app. Now persisted to `shared_preferences` (a plain UI
/// preference, not credential-adjacent, so this is the right storage —
/// contrast `pending_dependent_registration_provider.dart`'s deliberate
/// use of `flutter_secure_storage` instead).
///
/// [build] stays synchronous (so every existing call site reading
/// `accessibilityModeProvider` is unaffected) and still returns
/// [AccessibilityMode.standard] immediately — [_restore] then loads the
/// saved value right after and flips [state] if it was actually
/// high-contrast. That's a one-frame flash of the standard theme on cold
/// start in the saved-high-contrast case, not a blocking splash-style
/// wait; switching this to an `AsyncNotifier` to avoid even that flash
/// would mean every screen reading this provider has to unwrap an
/// `AsyncValue` instead of a plain `AccessibilityMode` — not worth it for
/// one frame.
class AccessibilityModeNotifier extends Notifier<AccessibilityMode> {
  static const _prefsKey = 'humsafar_accessibility_mode';

  @override
  AccessibilityMode build() {
    unawaited(_restore());
    return AccessibilityMode.standard;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_prefsKey) == AccessibilityMode.highContrast.name) {
      state = AccessibilityMode.highContrast;
    }
  }

  Future<void> _persist(AccessibilityMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }

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
    unawaited(_persist(state));
  }
}

final accessibilityModeProvider = NotifierProvider<AccessibilityModeNotifier, AccessibilityMode>(
  AccessibilityModeNotifier.new,
);
