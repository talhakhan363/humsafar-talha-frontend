import 'package:flutter/material.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

/// Task 3.10 — honest placeholder for a safety action whose real screen
/// is a separate, not-yet-built task. Originally covered all three of
/// Panic / Wellness Check / Medication; Tasks 3.11 and 3.12 (2026-10-20)
/// replaced the first two with their real screens (`PanicScreen`,
/// `WellnessCheckScreen`), so only `medication` is left here, waiting on
/// Task 3.13. Kept as its own small screen/enum rather than deleted
/// outright, since 3.13 will need the exact same pattern for its own
/// placeholder-to-real swap.
enum ComingSoonKind { medication }

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.kind});

  final ComingSoonKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (title, message) = switch (kind) {
      ComingSoonKind.medication => (l10n.myMedicineButtonLabel, l10n.medicationComingSoonMessage),
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
