import 'package:flutter/material.dart';

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
    final subtitleStyle = (textTheme.bodyLarge ?? const TextStyle(fontSize: 16)).copyWith(color: Colors.white70);

    return Material(
      color: Colors.red.shade700,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 160),
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
    final labelStyle =
        (textTheme.titleLarge ?? const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)).copyWith(color: Colors.teal.shade800);
    final subtitleStyle = (textTheme.bodyMedium ?? const TextStyle(fontSize: 14)).copyWith(color: Colors.grey.shade700);

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
            border: Border.all(color: Colors.teal, width: 2),
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
