import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
        const SnackBar(content: Text('Linked! You can now see this Dependent on your home screen.')),
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
    switch (e.code) {
      case 'GUARDIAN_NOT_VERIFIED':
        return 'You need to verify your own account before you can link a Dependent.';
      case 'SECONDARY_CANNOT_LINK':
        return 'Only a Primary Guardian can link a Dependent - your account is Secondary.';
      case 'DEPENDENT_NOT_FOUND':
        return 'No account found with that ID - double check it and try again.';
      case 'ALREADY_LINKED':
        return 'You\'re already linked to this Dependent.';
      case 'PRIMARY_ALREADY_EXISTS':
        return 'This Dependent already has a Primary Guardian.';
      case 'GUARDIAN_CAP_REACHED':
        return 'This Dependent already has the maximum of 3 Guardians.';
      default:
        return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Link a Dependent'),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Ask the Dependent for the ID shown on their verification screen, then enter it below.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dependentIdController,
                decoration: const InputDecoration(labelText: 'Dependent\'s ID'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'This field is required.' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Link'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
