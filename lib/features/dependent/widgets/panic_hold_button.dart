import 'package:flutter/material.dart';

import '../../../core/theme/humsafar_colors.dart';

/// Task 3.11 — the press-and-hold confirm button on the Panic screen
/// (mockup screen 21: "Need help? / Press and hold the button for 2
/// seconds"). Extracted as its own widget so the hold-to-confirm timing
/// is independently testable without the rest of PanicScreen's
/// ApiClient/provider wiring — see
/// test/features/dependent/panic_hold_button_test.dart.
///
/// Deliberately built on `onTapDown`/`onTapUp`/`onTapCancel` rather than
/// Flutter's built-in long-press gesture family. The built-in
/// `onLongPressStart` has its own internal recognition delay before it
/// even fires, which would stack on top of [holdDuration] and make the
/// total press time harder to reason about (and to drive precisely in a
/// widget test) than starting the fill animation the instant a finger
/// goes down.
///
/// Text sizes come from `Theme.of(context).textTheme`, same accessibility
/// reasoning as `PanicButton`/`SafetyActionButton` (FR-P2) — so this
/// still scales correctly with the large-text/high-contrast toggle.
///
/// No l10n lookup inside this widget, on purpose — [label], [subtitle]
/// and [semanticsLabel] are all passed in already resolved, same
/// convention as `PanicButton`/`SafetyActionButton`, and exactly what
/// `panic_hold_button_test.dart`'s doc comment calls out: this widget is
/// tested standalone, with a plain `MaterialApp` and no localization
/// delegates, so `AppLocalizations.of(context)` would hit a null check
/// here (fixed 2026-11-07, caught by that test going red after the
/// N-04 fix first tried calling it directly).
class PanicHoldButton extends StatefulWidget {
  const PanicHoldButton({
    super.key,
    required this.label,
    required this.subtitle,
    required this.semanticsLabel,
    required this.onHoldComplete,
    this.holdDuration = const Duration(seconds: 2),
    this.enabled = true,
  });

  final String label;
  final String subtitle;

  /// Bug fix (N-04, QA 3.16 Accessibility Results v1.0, E-02): a bare
  /// CircularProgressIndicator under this button exposed itself to
  /// TalkBack as an unexplained percent value. This replaces that for
  /// the whole button — see the `Semantics` wrapper in `build` below.
  final String semanticsLabel;

  final VoidCallback onHoldComplete;
  final Duration holdDuration;
  final bool enabled;

  @override
  State<PanicHoldButton> createState() => _PanicHoldButtonState();
}

class _PanicHoldButtonState extends State<PanicHoldButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.holdDuration)..addStatusListener(_onStatusChanged);
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onHoldComplete();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatusChanged);
    _controller.dispose();
    super.dispose();
  }

  void _startHold() {
    if (!widget.enabled) return;
    _controller.forward(from: 0);
  }

  void _cancelHold() {
    if (_controller.status == AnimationStatus.forward) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final baseTitleSize = textTheme.titleLarge?.fontSize ?? 22;
    final labelStyle = (textTheme.titleLarge ?? const TextStyle(fontWeight: FontWeight.w800))
        .copyWith(fontSize: baseTitleSize * 1.6, color: Colors.white, fontWeight: FontWeight.w800);
    // Bug fix (N-03, QA 3.16 Accessibility Results v1.0, B-04): white at
    // 70% opacity on the danger-red background measures 3.8:1, below the
    // 4.5:1 AA minimum (calculated from these exact colours — the
    // Accessibility Scanner doesn't flag text-with-transparency). Plain
    // white is 6.5:1, same fix already applied to "Press for help" on
    // the Panic button itself (safety_action_buttons.dart).
    final subtitleStyle = (textTheme.bodyLarge ?? const TextStyle(fontSize: 16)).copyWith(color: Colors.white);

    return Semantics(
      // Bug fix (N-04, QA 3.16 Accessibility Results v1.0, E-02): a bare
      // CircularProgressIndicator exposes itself to TalkBack as a percent
      // value, so this read as "0 percent" with no explanation — not
      // "sent on purpose" (the finding's own note), just unannounced.
      // ExcludeSemantics below hides the raw progress-ring/text nodes so
      // this one label is the only thing TalkBack reads for the whole
      // button, and it actually says what double-tap-and-hold does.
      label: widget.semanticsLabel,
      button: true,
      enabled: widget.enabled,
      child: ExcludeSemantics(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => _startHold(),
          onPointerUp: (_) => _cancelHold(),
          onPointerCancel: (_) => _cancelHold(),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 260,
                  height: 260,
                  child: CircularProgressIndicator(
                    value: _controller.value,
                    strokeWidth: 8,
                    // Fix #2 (Design Handoff v1.0, section 3): tokenized, but
                    // deliberately still red — fix #6's note is explicit that
                    // red stays on THIS hold-to-trigger button; only the
                    // post-trigger "help is coming" view (panic_screen.dart)
                    // moved off red.
                    backgroundColor: HumsafarColors.dangerTint,
                    valueColor: const AlwaysStoppedAnimation<Color>(HumsafarColors.danger),
                  ),
                ),
                Container(
                  width: 220,
                  height: 220,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.enabled ? HumsafarColors.danger : HumsafarColors.danger.withValues(alpha: 0.4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(widget.label, style: labelStyle, textAlign: TextAlign.center),
                        const SizedBox(height: 6),
                        Text(widget.subtitle, style: subtitleStyle, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
