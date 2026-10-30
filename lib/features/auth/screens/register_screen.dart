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

/// Task 1.11 built this UI against dummy data; Task 2.5 Step B wired
/// `_submit` to the real /auth/register (+ an immediate /auth/login for
/// Guardians, since register alone doesn't return tokens -
/// auth_contract.md section 2). Step E adds an optional invite-code field
/// for a brand-new person accepting a Secondary invitation in one step
/// (linkage_contract.md section 2, path 1) - entering a code here forces
/// the role to Guardian, since a Dependent can't be invited this way (the
/// backend itself rejects that combination with 422).
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
  final _inviteTokenController = TextEditingController();
  AppMode _selectedRole = AppMode.guardian;
  bool _isSubmitting = false;

  bool get _hasInvite => _inviteTokenController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _inviteTokenController.addListener(_onInviteTokenChanged);
  }

  void _onInviteTokenChanged() {
    if (_hasInvite && _selectedRole != AppMode.guardian) {
      setState(() => _selectedRole = AppMode.guardian);
    } else {
      // Rebuild so the segmented control re-enables/disables as the field
      // goes from empty to non-empty or back.
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _inviteTokenController.dispose();
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
        inviteToken: _hasInvite ? _inviteTokenController.text.trim() : null,
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
        final pending = PendingDependentRegistration(
          dependentId: user.userId,
          password: _passwordController.text,
        );
        ref.read(pendingDependentRegistrationProvider.notifier).state = pending;
        // Bug fix (2026-10-30): also persist, so an interrupted KYC can
        // resume on the next app launch — see
        // pending_dependent_registration_provider.dart's doc comment.
        await ref.read(pendingDependentRegistrationStorageProvider).save(pending);
        if (!mounted) return;
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
    final l10n = AppLocalizations.of(context)!;
    switch (e.code) {
      case 'EMAIL_ALREADY_REGISTERED':
        return l10n.emailAlreadyRegisteredError;
      case 'PHONE_ALREADY_REGISTERED':
        return l10n.phoneAlreadyRegisteredError;
      case 'ALREADY_REGISTERED':
        return l10n.accountAlreadyRegisteredError;
      case 'INVITE_INVALID':
        return l10n.inviteInvalidError;
      case 'INVITE_EXPIRED':
        return l10n.inviteExpiredError;
      case 'INVITE_NOT_FOR_YOU':
        return l10n.inviteNotForYouRegisterError;
      case 'GUARDIAN_CAP_REACHED':
        return l10n.guardianCapReachedError;
      case 'VALIDATION_ERROR':
        return l10n.genericValidationError;
      default:
        return e.message;
    }
  }

  // Bug fix (2026-10-30, user-reported): same back-button fix as
  // login_screen.dart — see that screen's doc comment for the full
  // explanation.
  void _onBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/role-select');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBack(context);
      },
      child: _buildScaffold(context, l10n),
    );
  }

  Widget _buildScaffold(BuildContext context, AppLocalizations l10n) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.registerScreenTitle),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      // Bug fix (2026-10-30): bottom-nav-bar overlap, see vitals_screen.dart.
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewPadding.bottom),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _inviteTokenController,
                decoration: InputDecoration(
                  labelText: l10n.inviteCodeOptionalLabel,
                  helperText: l10n.inviteCodeHelperText,
                ),
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
                onSelectionChanged: (_isSubmitting || _hasInvite)
                    ? null
                    : (selection) => setState(() => _selectedRole = selection.first),
              ),
              if (_hasInvite) ...[
                const SizedBox(height: 4),
                Text(l10n.roleLockedToGuardianNote, style: const TextStyle(fontSize: 12)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.registerButton),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isSubmitting ? null : () => context.push('/login'),
                child: Text(l10n.alreadyHaveAccountPrompt),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
