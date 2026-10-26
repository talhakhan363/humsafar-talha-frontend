import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/theme/humsafar_colors.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// New screen for Task 2.5 Step E. A verified Primary Guardian invites a
/// Secondary Guardian by phone: POST /dependents/{id}/guardians/invite
/// (linkage_contract.md section 2). The returned invite_token is valid 7
/// days and works only for that phone number - shared outside the app
/// (WhatsApp/SMS), which is why this screen just surfaces it to copy.
class InviteSecondaryScreen extends ConsumerStatefulWidget {
  const InviteSecondaryScreen({super.key, required this.dependentId});

  final String dependentId;

  @override
  ConsumerState<InviteSecondaryScreen> createState() => _InviteSecondaryScreenState();
}

class _InviteSecondaryScreenState extends ConsumerState<InviteSecondaryScreen> {
  static final _pakPhoneRegExp = RegExp(r'^(\+92|0)3\d{9}$');

  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;
  String? _inviteToken;
  int? _expiresIn;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final response = await ref.read(apiClientProvider).post<Map<String, dynamic>>(
            '/dependents/${widget.dependentId}/guardians/invite',
            data: {'phone': _phoneController.text.trim()},
          );
      if (!mounted) return;
      setState(() {
        _inviteToken = response.data?['invite_token'] as String?;
        _expiresIn = response.data?['expires_in'] as int?;
      });
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
      case 'GUARDIAN_NOT_VERIFIED':
        return l10n.guardianNotVerifiedGenericError;
      case 'NOT_PRIMARY_GUARDIAN':
        return l10n.notPrimaryGuardianError;
      case 'GUARDIAN_CAP_REACHED':
        return l10n.guardianCapReachedError;
      case 'INVITEE_NOT_ELIGIBLE':
        return l10n.inviteeNotEligibleError;
      case 'VALIDATION_ERROR':
        return l10n.invitePhoneValidationError;
      default:
        return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inviteASecondaryButton),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _inviteToken == null ? _buildForm(l10n) : _buildResult(l10n),
      ),
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.invitePhoneInstructions),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: l10n.phoneLabel, hintText: '03XXXXXXXXX'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return l10n.fieldRequiredError;
              if (!_pakPhoneRegExp.hasMatch(value.trim())) return l10n.invalidPhoneError;
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.sendInviteButton),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(AppLocalizations l10n) {
    final days = _expiresIn != null ? (_expiresIn! / 86400).round() : 7;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, size: 48, color: HumsafarColors.success),
        const SizedBox(height: 16),
        Text(l10n.inviteCreatedMessage(days), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        SelectableText(
          _inviteToken ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _inviteToken ?? ''));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.copiedSnackbar)));
          },
          icon: const Icon(Icons.copy),
          label: Text(l10n.copyCodeButton),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.inviteShareFooterNote,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
