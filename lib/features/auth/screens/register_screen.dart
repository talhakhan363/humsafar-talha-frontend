import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/auth/pending_dependent_registration_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../providers/app_mode_provider.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// Task 1.11 built this UI against dummy data; Task 2.5 wires `_submit` to
/// Abdullah's real /auth/register (+ an immediate /auth/login for
/// Guardians, since register alone doesn't return tokens —
/// auth_contract.md section 2). Fields/validators unchanged from 1.11.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static final _pakPhoneRegExp = RegExp(r'^(\+92|0)3\d{9}$');

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  AppMode _selectedRole = AppMode.guardian;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final authRepository = ref.read(authRepositoryProvider);
    final role = _selectedRole == AppMode.guardian ? 'guardian' : 'dependent';

    try {
      final user = await authRepository.register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        role: role,
      );

      ref.read(appModeProvider.notifier).state = _selectedRole;
      if (!mounted) return;

      if (_selectedRole == AppMode.guardian) {
        await authRepository.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (!mounted) return;
        context.go('/kyc/guardian');
      } else {
        ref.read(pendingDependentRegistrationProvider.notifier).state = PendingDependentRegistration(
          dependentId: user.userId,
          password: _passwordController.text,
        );
        context.go('/kyc/dependent');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_messageFor(e))));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _messageFor(ApiException e) {
    switch (e.code) {
      case 'EMAIL_ALREADY_REGISTERED':
        return 'This email is already registered. Try logging in instead.';
      case 'PHONE_ALREADY_REGISTERED':
        return 'This phone number is already registered.';
      case 'ALREADY_REGISTERED':
        return 'This account already exists. Try logging in instead.';
      case 'VALIDATION_ERROR':
        return 'Please check the fields and try again.';
      default:
        return e.message;
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
                validator: (value) => (value == null || value.trim().isEmpty) ? l10n.fieldRequiredError : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: l10n.emailLabel),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return l10n.fieldRequiredError;
                  if (!value.contains('@') || !value.contains('.')) return l10n.invalidEmailError;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: l10n.phoneLabel),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return l10n.fieldRequiredError;
                  if (!_pakPhoneRegExp.hasMatch(value.trim())) return l10n.invalidPhoneError;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.passwordLabel),
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.fieldRequiredError;
                  if (value.length < 8) return l10n.passwordTooShortError;
                  final hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
                  final hasDigit = RegExp(r'\d').hasMatch(value);
                  if (!hasLetter || !hasDigit) return l10n.passwordTooWeakError;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.confirmPasswordLabel),
                validator: (value) => value != _passwordController.text ? l10n.passwordsDoNotMatchError : null,
              ),
              const SizedBox(height: 24),
              Text(l10n.registeringAsLabel, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              SegmentedButton<AppMode>(
                segments: [
                  ButtonSegment(value: AppMode.guardian, label: Text(l10n.roleGuardianOption)),
                  ButtonSegment(value: AppMode.dependent, label: Text(l10n.roleDependentOption)),
                ],
                selected: {_selectedRole},
                onSelectionChanged: _isSubmitting ? null : (selection) => setState(() => _selectedRole = selection.first),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.registerButton),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isSubmitting ? null : () => context.go('/login'),
                child: Text(l10n.alreadyHaveAccountPrompt),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
