import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// New screen for Task 2.5 Step E. A verified Primary Guardian enters a
/// Dependent's user_id (the Dependent sees/shares this from their own KYC
/// screen - see dependent_kyc_screen.dart's "waiting for guardian" view)
/// and links to them: POST /dependents/{id}/link (linkage_contract.md
/// section 2). No body - the id in the path is everything.
class LinkDependentScreen extends ConsumerStatefulWidget {
  const LinkDependentScreen({super.key});

  @override
  ConsumerState<LinkDependentScreen> createState() => _LinkDependentScreenState();
}

class _LinkDependentScreenState extends ConsumerState<LinkDependentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dependentIdController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _dependentIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(apiClientProvider).post('/dependents/${_dependentIdController.text.trim()}/link');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.linkedSuccessSnackbar)),
      );
      context.pop(true);
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
        return l10n.guardianNotVerifiedLinkError;
      case 'SECONDARY_CANNOT_LINK':
        return l10n.secondaryCannotLinkError;
      case 'DEPENDENT_NOT_FOUND':
        return l10n.dependentNotFoundError;
      case 'ALREADY_LINKED':
        return l10n.alreadyLinkedError;
      case 'PRIMARY_ALREADY_EXISTS':
        return l10n.primaryAlreadyExistsError;
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
        title: Text(l10n.linkADependentLabel),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      // Bug fix (2026-10-30): bottom-nav-bar overlap, see vitals_screen.dart.
      body: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewPadding.bottom),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.linkDependentInstructions),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dependentIdController,
                decoration: InputDecoration(labelText: l10n.dependentIdLabel),
                validator: (value) => (value == null || value.trim().isEmpty) ? l10n.fieldRequiredError : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.linkButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
