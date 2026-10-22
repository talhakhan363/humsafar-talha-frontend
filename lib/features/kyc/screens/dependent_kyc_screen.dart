import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/auth/pending_dependent_registration_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// Task 1.11 built this UI against dummy data; Task 2.5 Step C2 wires it to
/// the real POST /dependents/{id}/kyc-verify (kyc_contract.md section 1).
///
/// Two things changed beyond "swap the submit handler":
/// 1. The liveness button now actually takes a photo via `image_picker`
///    (camera capture) and base64-encodes it for `liveness_image`, instead
///    of flipping a local bool. This is still NOT the real liveness-
///    detection SDK the old class comment mentioned - that vendor isn't
///    chosen yet, and the backend check is a mock anyway (it just looks
///    for a "FAIL" prefix in the string). A real anti-spoofing SDK is a
///    separate, later swap; this just makes the button genuinely capture
///    and submit a photo instead of doing nothing.
/// 2. This screen has no JWT to call anything with - a Dependent who just
///    registered has no token (SDS 11.3). Instead it reads the id+password
///    stashed by register_screen.dart in
///    [pendingDependentRegistrationProvider] and sends the password
///    directly in the request body, per kyc_contract.md section 1.
class DependentKycScreen extends ConsumerStatefulWidget {
  const DependentKycScreen({super.key});

  @override
  ConsumerState<DependentKycScreen> createState() => _DependentKycScreenState();
}

class _DependentKycScreenState extends ConsumerState<DependentKycScreen> {
  static final _cnicRegExp = RegExp(r'^\d{5}-\d{7}-\d{1}$');

  final _formKey = GlobalKey<FormState>();
  final _cnicController = TextEditingController();
  final _imagePicker = ImagePicker();

  Uint8List? _livenessPhotoBytes;
  bool _isCapturing = false;
  bool _isSubmitting = false;
  _KycOutcome? _outcome;

  @override
  void dispose() {
    _cnicController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _livenessPhotoBytes != null;

  Future<void> _captureLiveness() async {
    setState(() => _isCapturing = true);
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        imageQuality: 70,
      );
      if (photo == null) return; // user cancelled
      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      setState(() => _livenessPhotoBytes = bytes);
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_livenessPhotoBytes == null) return;

    final pending = ref.read(pendingDependentRegistrationProvider);
    if (pending == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.lostRegistrationDetailsError),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await ref.read(apiClientProvider).post<Map<String, dynamic>>(
        '/dependents/${pending.dependentId}/kyc-verify',
        data: {
          'password': pending.password,
          'cnic': _cnicController.text.trim(),
          'liveness_image': base64Encode(_livenessPhotoBytes!),
        },
      );
      final status = response.data?['status'] as String?;
      final nextStep = response.data?['next_step'] as String?;
      final message = response.data?['message'] as String?;
      if (!mounted) return;

      setState(() => _outcome = _KycOutcome(status: status, nextStep: nextStep, message: message));

      // Once genuinely verified, the password has done its job - drop it
      // rather than hold it in memory any longer than needed.
      if (status == 'verified') {
        ref.read(pendingDependentRegistrationProvider.notifier).state = null;
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_messageFor(e))));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _messageFor(ApiException e) {
    final l10n = AppLocalizations.of(context)!;
    switch (e.code) {
      case 'INVALID_CREDENTIALS':
        return l10n.kycInvalidCredentialsError;
      case 'ALREADY_VERIFIED':
        return l10n.kycAlreadyVerifiedError;
      case 'CNIC_ALREADY_REGISTERED':
        return l10n.cnicAlreadyRegisteredError;
      case 'VALIDATION_ERROR':
        return l10n.kycValidationError;
      default:
        return e.message;
    }
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
        child: _outcome == null ? _buildForm(l10n) : _buildOutcome(l10n, _outcome!),
      ),
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _cnicController,
            decoration: InputDecoration(labelText: l10n.cnicLabel, hintText: l10n.cnicHint),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return l10n.fieldRequiredError;
              if (!_cnicRegExp.hasMatch(value.trim())) return l10n.invalidCnicError;
              return null;
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _isCapturing ? null : _captureLiveness,
            icon: Icon(_livenessPhotoBytes != null ? Icons.check_circle : Icons.camera_alt),
            label: Text(
              _isCapturing
                  ? l10n.openingCameraLabel
                  : _livenessPhotoBytes != null
                      ? l10n.livenessCapturedConfirmation
                      : l10n.captureLivenessButton,
            ),
          ),
          if (_livenessPhotoBytes != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(_livenessPhotoBytes!, height: 120),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (_canSubmit && !_isSubmitting) ? _submit : null,
            child: _isSubmitting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.submitForVerificationButton),
          ),
        ],
      ),
    );
  }

  Widget _buildOutcome(AppLocalizations l10n, _KycOutcome outcome) {
    final dependentId = ref.read(pendingDependentRegistrationProvider)?.dependentId;

    if (outcome.status == 'verified' && outcome.nextStep == 'link_primary_guardian') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.hourglass_top, size: 48),
          const SizedBox(height: 16),
          Text(
            outcome.message ?? l10n.kycVerifiedWaitingDefaultMessage,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(l10n.shareIdWithGuardianLabel, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          // Screen 05 fix: was plain SelectableText here (hard for an
          // elderly Dependent to copy, per Sarim's design-check note on
          // this task) — now opens the dedicated Share-My-ID screen
          // (QR code, Copy ID, Share), matching Sarim's mockup 05.
          ElevatedButton.icon(
            onPressed: dependentId == null ? null : () => context.push('/dependent/share-id', extra: dependentId),
            icon: const Icon(Icons.qr_code),
            label: Text(l10n.viewShareMyIdButton),
          ),
        ],
      );
    }

    if (outcome.status == 'verified' && outcome.nextStep == 'none') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle, size: 48, color: Colors.green),
          const SizedBox(height: 16),
          Text(outcome.message ?? l10n.kycVerifiedActiveDefaultMessage, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            child: Text(l10n.goToLoginButton),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          outcome.status == 'pending' ? Icons.hourglass_top : Icons.error_outline,
          size: 48,
          color: outcome.status == 'failed' ? Colors.red : null,
        ),
        const SizedBox(height: 16),
        Text(
          outcome.message ?? (outcome.status == 'pending' ? l10n.kycPendingDefaultMessage : l10n.kycFailedDefaultMessage),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => setState(() {
            _outcome = null;
            _livenessPhotoBytes = null;
          }),
          child: Text(l10n.tryAgainButton),
        ),
      ],
    );
  }
}

class _KycOutcome {
  const _KycOutcome({this.status, this.nextStep, this.message});
  final String? status;
  final String? nextStep;
  final String? message;
}
