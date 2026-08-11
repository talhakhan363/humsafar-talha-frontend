import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// Task 1.11 — Guardian identity verification (FR-A3). UI only, dummy data.
///
/// Deliberately does NOT include a liveness photo capture step — FR-A3
/// states explicitly: "Guardian verification shall not require liveness
/// photo capture." That's the Dependent-only requirement (FR-A2), built
/// separately in DependentKycScreen. Don't "fix" this by adding a camera
/// step here later; the asymmetry between the two screens is intentional,
/// straight from the SRS.
class GuardianVerificationScreen extends StatefulWidget {
  const GuardianVerificationScreen({super.key});

  @override
  State<GuardianVerificationScreen> createState() =>
      _GuardianVerificationScreenState();
}

class _GuardianVerificationScreenState
    extends State<GuardianVerificationScreen> {
  final _cnicController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;

  @override
  void dispose() {
    _cnicController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _sendOtp(AppLocalizations l10n) {
    if (_cnicController.text.trim().isEmpty) return;
    setState(() => _otpSent = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.otpSentDummyMessage)),
    );
  }

  void _verifyAndContinue() {
    if (_cnicController.text.trim().isEmpty ||
        _otpController.text.trim().isEmpty) {
      return;
    }
    // Dummy verification only — real CNIC/OTP validation happens once
    // Task 1.4 (KYC endpoints) is wired in at Task 2.5.
    context.go('/guardian');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.guardianVerificationTitle),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.noLivenessRequiredNote,
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cnicController,
              decoration: InputDecoration(
                labelText: l10n.cnicLabel,
                hintText: l10n.cnicHint,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _sendOtp(l10n),
              child: Text(l10n.sendOtpButton),
            ),
            if (_otpSent) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.otpLabel),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _verifyAndContinue,
              child: Text(l10n.verifyAndContinueButton),
            ),
          ],
        ),
      ),
    );
  }
}
