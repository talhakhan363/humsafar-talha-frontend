import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// Task 1.11 — Dependent KYC (FR-A2). UI only, dummy data.
///
/// FR-A2 requires a CNIC number AND a real-time liveness photo capture,
/// and gates account activation on both succeeding plus linkage to a
/// Primary Guardian (FR-B1). The real liveness check needs a 3rd-party
/// SDK (per the Final Feature Set Report) that isn't integrated yet — the
/// button below is a placeholder that just flips a local "captured" flag.
/// Swap its onPressed for the real SDK call once that vendor is chosen;
/// the rest of this screen (CNIC field, submit gating) shouldn't need to
/// change.
class DependentKycScreen extends StatefulWidget {
  const DependentKycScreen({super.key});

  @override
  State<DependentKycScreen> createState() => _DependentKycScreenState();
}

class _DependentKycScreenState extends State<DependentKycScreen> {
  final _cnicController = TextEditingController();
  bool _livenessCaptured = false;

  @override
  void dispose() {
    _cnicController.dispose();
    super.dispose();
  }

  void _captureLiveness() {
    // Placeholder — see the class doc comment above.
    setState(() => _livenessCaptured = true);
  }

  bool get _canSubmit =>
      _cnicController.text.trim().isNotEmpty && _livenessCaptured;

  void _submit() {
    if (!_canSubmit) return;
    // Dummy submission only — real KYC endpoint wiring happens once
    // Task 1.4 is available, at Task 2.5.
    context.go('/dependent');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dependentKycTitle),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _cnicController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.cnicLabel,
                hintText: l10n.cnicHint,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _captureLiveness,
              icon: Icon(
                  _livenessCaptured ? Icons.check_circle : Icons.camera_alt),
              label: Text(
                _livenessCaptured
                    ? l10n.livenessCapturedConfirmation
                    : l10n.captureLivenessButton,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _canSubmit ? _submit : null,
              child: Text(l10n.submitForVerificationButton),
            ),
          ],
        ),
      ),
    );
  }
}
