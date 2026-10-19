import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// Task 1.11 built this UI against dummy data; Task 2.5 Step C wires it to
/// the real /guardians/me/* endpoints (kyc_contract.md section 2).
///
/// Shape change from the original dummy flow, and the reason this screen
/// looks different now: the backend treats phone-OTP and CNIC as two
/// INDEPENDENT ways to verify — passing either one is enough
/// ("verified when the phone OTP OR the CNIC check has passed"). The
/// original UI chained CNIC-then-OTP as one sequence, which doesn't match
/// that, so this is now two separate sections, either of which completes
/// verification on its own.
///
/// Unchanged from 1.11: no liveness photo step here — FR-A3 explicitly
/// excludes it for Guardians (DependentKycScreen is where that lives).
class GuardianVerificationScreen extends ConsumerStatefulWidget {
  const GuardianVerificationScreen({super.key});

  @override
  ConsumerState<GuardianVerificationScreen> createState() => _GuardianVerificationScreenState();
}

class _GuardianVerificationScreenState extends ConsumerState<GuardianVerificationScreen> {
  static final _cnicRegExp = RegExp(r'^\d{5}-\d{7}-\d{1}$');

  final _otpFormKey = GlobalKey<FormState>();
  final _cnicFormKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _cnicController = TextEditingController();

  bool _otpSent = false;
  bool _isSendingOtp = false;
  bool _isConfirmingOtp = false;
  bool _isVerifyingCnic = false;

  @override
  void dispose() {
    _otpController.dispose();
    _cnicController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() => _isSendingOtp = true);
    try {
      await ref.read(apiClientProvider).post('/guardians/me/verify-phone/request');
      if (!mounted) return;
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent to your registered phone number.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _confirmOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;
    setState(() => _isConfirmingOtp = true);
    try {
      final response = await ref.read(apiClientProvider).post<Map<String, dynamic>>(
        '/guardians/me/verify-phone/confirm',
        data: {'code': _otpController.text.trim()},
      );
      final verified = (response.data?['verified'] as bool?) ?? false;
      if (!mounted) return;
      if (verified) {
        context.go('/guardian');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Not verified yet — try the CNIC check below instead.")),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_otpErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _isConfirmingOtp = false);
    }
  }

  Future<void> _verifyCnic() async {
    if (!_cnicFormKey.currentState!.validate()) return;
    setState(() => _isVerifyingCnic = true);
    try {
      final response = await ref.read(apiClientProvider).post<Map<String, dynamic>>(
        '/guardians/me/verify-cnic',
        data: {'cnic': _cnicController.text.trim()},
      );
      final status = response.data?['status'] as String?;
      if (!mounted) return;
      if (status == 'verified') {
        context.go('/guardian');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CNIC check failed — try the phone OTP above instead.')),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isVerifyingCnic = false);
    }
  }

  String _otpErrorMessage(ApiException e) {
    if (e.code == 'OTP_INVALID') return 'That code is wrong or expired. Try again or resend.';
    return e.message;
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
            const SizedBox(height: 8),
            const Text("Either option below is enough to verify your account — you don't need to do both."),
            const Divider(height: 32),
            Text('Option A: verify by phone OTP', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isSendingOtp ? null : _sendOtp,
              child: _isSendingOtp
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_otpSent ? 'Resend OTP' : l10n.sendOtpButton),
            ),
            if (_otpSent) ...[
              const SizedBox(height: 16),
              Form(
                key: _otpFormKey,
                child: TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.otpLabel),
                  validator: (value) => (value == null || value.trim().isEmpty) ? l10n.fieldRequiredError : null,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isConfirmingOtp ? null : _confirmOtp,
                child: _isConfirmingOtp
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.verifyAndContinueButton),
              ),
            ],
            const Divider(height: 32),
            Text('Option B: verify by CNIC', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Form(
              key: _cnicFormKey,
              child: TextFormField(
                controller: _cnicController,
                decoration: InputDecoration(labelText: l10n.cnicLabel, hintText: l10n.cnicHint),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return l10n.fieldRequiredError;
                  if (!_cnicRegExp.hasMatch(value.trim())) return l10n.invalidCnicError;
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isVerifyingCnic ? null : _verifyCnic,
              child: _isVerifyingCnic
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.verifyAndContinueButton),
            ),
          ],
        ),
      ),
    );
  }
}
