import 'package:flutter/material.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

/// Task 3.10 — the three safety actions (Panic, Wellness Check,
/// Medication) are real destinations as of this task, but their actual
/// screens are separate tasks (3.11, 3.12, 3.13). Rather than leaving
/// the Home screen's buttons pointing nowhere, each routes to this
/// honest placeholder, matching the exact placeholder pattern already
/// used for Guardian/Dependent home from Task 1.11 onward — named here,
/// not a silent gap.
enum ComingSoonKind { panic, wellnessCheck, medication }

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.kind});

  final ComingSoonKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (title, message) = switch (kind) {
      ComingSoonKind.panic => (l10n.panicButtonLabel, l10n.panicComingSoonMessage),
      ComingSoonKind.wellnessCheck => (l10n.iAmOkButtonLabel, l10n.wellnessCheckComingSoonMessage),
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
