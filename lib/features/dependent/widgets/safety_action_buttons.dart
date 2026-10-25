import 'package:flutter/material.dart';

import '../../../core/theme/humsafar_colors.dart';

/// Task 3.10 — the big, high-contrast-aware action buttons on the
/// Dependent home screen (mockup screen 20). Public (not private to the
/// screen file) so they're independently widget-testable — see
/// test/features/dependent/safety_action_buttons_test.dart.
///
/// Per Sarim's 3.9 design note: "Dependent screens use 22–38 px text and
/// 96–200 px tall buttons." Text sizes are derived from
/// `Theme.of(context).textTheme` rather than hardcoded, so they still
/// scale correctly when the large-text/high-contrast toggle (Task 1.9,
/// FR-P2) is on — a hardcoded fontSize would silently ignore that
/// toggle, which defeats its whole point on what's meant to be one of
/// the most accessibility-critical screens in the app.

/// The full-width red Panic button. Deliberately the only place in the
/// Dependent-facing UI that uses red outside a genuine critical state —
/// matches Sarim's "red reserved for Panic/critical only" rule.
class PanicButton extends StatelessWidget {
  const PanicButton({super.key, required this.onTap, required this.label, required this.subtitle});

  final VoidCallback onTap;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final baseTitleSize = textTheme.titleLarge?.fontSize ?? 22;
    final labelStyle = (textTheme.titleLarge ?? const TextStyle(fontWeight: FontWeight.w700))
        .copyWith(fontSize: baseTitleSize * 1.4, color: Colors.white);
    // Fixed 2026-10-25 — Design Handoff v1.0 fix #3: white70-on-red.shade700
    // was only 3.12:1, below the 4.5:1 AA minimum on this safety-critical
    // screen. Plain white on the handoff's danger token is 5.30:1.
    final subtitleStyle = (textTheme.bodyLarge ?? const TextStyle(fontSize: 16)).copyWith(color: Colors.white);

    return Material(
      // Fix #2 (section 3): was Colors.red.shade700 — now the handoff's
      // danger token, reserved for Panic/critical alerts only.
      color: HumsafarColors.danger,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          // Fixed 2026-10-25 — Design Handoff v1.0 fix #4: mockup 20 has
          // this button 200px tall, not 160.
          constraints: const BoxConstraints(minHeight: 200),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.white, size: 40),
              const SizedBox(height: 8),
              Text(label, style: labelStyle, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(subtitle, style: subtitleStyle, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

/// The outlined teal buttons for "I am OK" and "My medicine" — same
/// shape, different label/subtitle/destination per call site.
class SafetyActionButton extends StatelessWidget {
  const SafetyActionButton({super.key, required this.onTap, required this.label, required this.subtitle});

  final VoidCallback onTap;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Fix #2 (section 3): was Colors.teal.shade800 / Colors.grey.shade700 /
    // Colors.teal — now the handoff's primaryDark/muted/primary tokens.
    final labelStyle =
        (textTheme.titleLarge ?? const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)).copyWith(color: HumsafarColors.primaryDark);
    final subtitleStyle = (textTheme.bodyMedium ?? const TextStyle(fontSize: 14)).copyWith(color: HumsafarColors.muted);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 110),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: HumsafarColors.primary, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: labelStyle, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(subtitle, style: subtitleStyle, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
