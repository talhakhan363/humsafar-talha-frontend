import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

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
        SnackBar(content: Text(AppLocalizations.of(context)!.inviteAcceptedSnackbar)),
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
    final l10n = AppLocalizations.of(context)!;
    switch (e.code) {
      case 'INVITE_INVALID':
        return l10n.inviteInvalidError;
      case 'INVITE_EXPIRED':
        return l10n.inviteExpiredError;
      case 'PRIMARY_CANNOT_ACCEPT_INVITE':
        return l10n.primaryCannotAcceptInviteError;
      case 'INVITE_NOT_FOR_YOU':
        return l10n.inviteNotForYouAcceptError;
      case 'ALREADY_LINKED':
        return l10n.alreadyLinkedError;
      case 'GUARDIAN_CAP_REACHED':
        return l10n.guardianCapReachedError;
      default:
        return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.acceptAnInviteTitle),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.pasteInviteCodeInstructions),
              const SizedBox(height: 16),
              TextFormField(
                controller: _inviteTokenController,
                decoration: InputDecoration(labelText: l10n.inviteCodeLabel),
                validator: (value) => (value == null || value.trim().isEmpty) ? l10n.fieldRequiredError : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.acceptButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
