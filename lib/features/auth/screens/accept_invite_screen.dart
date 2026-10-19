import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';

/// New screen for Task 2.5 Step E. For an EXISTING logged-in Secondary
/// Guardian account joining another Dependent via an invite code:
/// POST /invitations/accept (linkage_contract.md section 2, path 2). A
/// brand-new person accepting an invite instead goes through
/// register_screen.dart's optional invite-code field, which is path 1 of
/// the same section and a different endpoint (/auth/register).
class AcceptInviteScreen extends ConsumerStatefulWidget {
  const AcceptInviteScreen({super.key});

  @override
  ConsumerState<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends ConsumerState<AcceptInviteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inviteTokenController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _inviteTokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(apiClientProvider).post(
            '/invitations/accept',
            data: {'invite_token': _inviteTokenController.text.trim()},
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Accepted! This Dependent now shows on your home screen.')),
      );
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_messageFor(e))));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _messageFor(ApiException e) {
    switch (e.code) {
      case 'INVITE_INVALID':
        return 'That code isn\'t valid.';
      case 'INVITE_EXPIRED':
        return 'That code has expired - ask for a new one.';
      case 'PRIMARY_CANNOT_ACCEPT_INVITE':
        return 'A Primary Guardian account can\'t accept a Secondary invite.';
      case 'INVITE_NOT_FOR_YOU':
        return 'This code was sent to a different phone number than the one on your account.';
      case 'ALREADY_LINKED':
        return 'You\'re already linked to this Dependent.';
      case 'GUARDIAN_CAP_REACHED':
        return 'This Dependent already has the maximum of 3 Guardians.';
      default:
        return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accept an invite')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Paste the invite code a Primary Guardian shared with you.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _inviteTokenController,
                decoration: const InputDecoration(labelText: 'Invite code'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'This field is required.' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Accept'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
