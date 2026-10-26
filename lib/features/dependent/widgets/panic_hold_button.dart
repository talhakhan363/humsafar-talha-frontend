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
class PanicHoldButton extends StatefulWidget {
  const PanicHoldButton({
    super.key,
    required this.label,
    required this.subtitle,
    required this.onHoldComplete,
    this.holdDuration = const Duration(seconds: 2),
    this.enabled = true,
  });

  final String label;
  final String subtitle;
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
    final subtitleStyle = (textTheme.bodyLarge ?? const TextStyle(fontSize: 16)).copyWith(color: Colors.white70);

    return Listener(
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
    );
  }
}
