import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
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
    switch (e.code) {
      case 'GUARDIAN_NOT_VERIFIED':
        return 'You need to verify your own account first.';
      case 'NOT_PRIMARY_GUARDIAN':
        return 'You\'re not this Dependent\'s Primary Guardian.';
      case 'GUARDIAN_CAP_REACHED':
        return 'This Dependent already has the maximum of 3 Guardians.';
      case 'INVITEE_NOT_ELIGIBLE':
        return 'That number can\'t be invited (it may already belong to an account, or be the Dependent\'s own number).';
      case 'VALIDATION_ERROR':
        return 'Please check the phone number and try again.';
      default:
        return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite a Secondary Guardian'),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _inviteToken == null ? _buildForm() : _buildResult(),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Enter the Secondary Guardian\'s phone number. They\'ll need the code this generates.'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone number', hintText: '03XXXXXXXXX'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'This field is required.';
              if (!_pakPhoneRegExp.hasMatch(value.trim())) return 'Enter a valid Pakistani phone number.';
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Send invite'),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final days = _expiresIn != null ? (_expiresIn! / 86400).round() : 7;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, size: 48, color: Colors.green),
        const SizedBox(height: 16),
        Text('Invite created - valid for $days days. Share this code with them:', textAlign: TextAlign.center),
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
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied.')));
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy code'),
        ),
        const SizedBox(height: 8),
        const Text(
          'They enter this during registration (if they\'re new) or on the "Have an invite code?" screen (if they already have a Secondary account).',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
