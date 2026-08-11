import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../providers/app_mode_provider.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// Task 1.11 — static registration screen (FR-A1: role-based registration).
///
/// UI only, dummy data — there's no backend yet (Abdullah's Auth API is
/// Task 1.3). Submitting just validates the form locally and navigates to
/// the correct role-specific KYC screen. Real API wiring happens at
/// Task 2.5, once 1.3 exists — this screen's fields and validation logic
/// shouldn't need to change then, only the submit handler's body.
///
/// Note what's deliberately NOT here: a Primary/Secondary Guardian picker.
/// Per FR-A1, that designation isn't chosen at registration — it's decided
/// by behavior (an account that independently creates its first Dependent
/// becomes Primary; one created solely by accepting an invite becomes
/// Secondary). That logic belongs in the linkage flow (Task 1.5 backend /
/// its frontend counterpart), not here.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  AppMode _selectedRole = AppMode.guardian;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Dummy data only — Task 1.11 scope. Real registration happens once
    // Task 1.3 (Auth API) is wired in at Task 2.5.
    ref.read(appModeProvider.notifier).state = _selectedRole;

    if (_selectedRole == AppMode.guardian) {
      context.go('/kyc/guardian');
    } else {
      context.go('/kyc/dependent');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.registerScreenTitle),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.fullNameLabel),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.fieldRequiredError
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: l10n.emailLabel),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.fieldRequiredError;
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return l10n.invalidEmailError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: l10n.phoneLabel),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.fieldRequiredError
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.passwordLabel),
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.fieldRequiredError;
                  if (value.length < 6) return l10n.passwordTooShortError;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration:
                    InputDecoration(labelText: l10n.confirmPasswordLabel),
                validator: (value) => value != _passwordController.text
                    ? l10n.passwordsDoNotMatchError
                    : null,
              ),
              const SizedBox(height: 24),
              Text(l10n.registeringAsLabel,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              SegmentedButton<AppMode>(
                segments: [
                  ButtonSegment(
                    value: AppMode.guardian,
                    label: Text(l10n.roleGuardianOption),
                  ),
                  ButtonSegment(
                    value: AppMode.dependent,
                    label: Text(l10n.roleDependentOption),
                  ),
                ],
                selected: {_selectedRole},
                onSelectionChanged: (selection) {
                  setState(() => _selectedRole = selection.first);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: Text(l10n.registerButton),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(l10n.alreadyHaveAccountPrompt),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
