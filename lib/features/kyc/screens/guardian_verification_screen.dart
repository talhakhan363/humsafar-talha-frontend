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
  // Pakistani CNIC format: 5 digits - 7 digits - 1 digit, matching the
  // cnicHint shown on the field. Client-side format check only — real CNIC
  // verification happens via the third-party KYC provider server-side
  // (FR-A3), wired in at Task 2.5 once Task 1.4 exists.
  static final _cnicRegExp = RegExp(r'^\d{5}-\d{7}-\d{1}$');

  final _cnicFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
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
    if (!_cnicFormKey.currentState!.validate()) return;
    setState(() => _otpSent = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.otpSentDummyMessage)),
    );
  }

  void _verifyAndContinue() {
    if (!_cnicFormKey.currentState!.validate()) return;
    if (_otpSent && !_otpFormKey.currentState!.validate()) return;
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
            Form(
              key: _cnicFormKey,
              child: TextFormField(
                controller: _cnicController,
                decoration: InputDecoration(
                  labelText: l10n.cnicLabel,
                  hintText: l10n.cnicHint,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.fieldRequiredError;
                  }
                  if (!_cnicRegExp.hasMatch(value.trim())) {
                    return l10n.invalidCnicError;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _sendOtp(l10n),
              child: Text(l10n.sendOtpButton),
            ),
            if (_otpSent) ...[
              const SizedBox(height: 16),
              Form(
                key: _otpFormKey,
                child: TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.otpLabel),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? l10n.fieldRequiredError
                      : null,
                ),
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
