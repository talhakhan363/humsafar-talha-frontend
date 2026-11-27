import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/auth/pending_dependent_registration_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/theme/humsafar_colors.dart';
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
  // Bug fix (Sarim's 22 Nov Welcome-screen handoff): the new Welcome
  // screen (01, welcome_screen.dart) asks "Who is using this phone?"
  // before Create account ever appears, so the role toggle below
  // shouldn't make the person choose twice. Optional and defaults to
  // null (falls back to the segmented control's own existing
  // AppMode.guardian default below) so every other caller of this screen
  // — the dev "Preview" link on role_select_screen.dart in particular —
  // keeps behaving exactly as before.
  const RegisterScreen({super.key, this.initialRole});

  final AppMode? initialRole;

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
  late AppMode _selectedRole = widget.initialRole ?? AppMode.guardian;
  bool _isSubmitting = false;

  // Bug fix (Sarim's 23 Nov Privacy/Terms spec): the two tappable words in
  // the new consent line below the button. Built once and disposed in
  // [dispose], same reasoning as the TextEditingControllers above —
  // GestureRecognizers aren't free to leave ungarbage-collected if this
  // screen gets built many times (e.g. re-opened from the back-button
  // history), and the project already disposes everything disposable here.
  late final TapGestureRecognizer _privacyLinkRecognizer = TapGestureRecognizer()
    ..onTap = () => context.push('/legal/privacy');
  late final TapGestureRecognizer _termsLinkRecognizer = TapGestureRecognizer()
    ..onTap = () => context.push('/legal/terms');

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
    _privacyLinkRecognizer.dispose();
    _termsLinkRecognizer.dispose();
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
      // Bug fix (F-21, Sarim's 9 Nov report): see login_screen.dart's
      // _messageFor doc comment.
      case 'unexpected_error':
        return l10n.cantReachServerError;
      default:
        return e.message;
    }
  }

  // Bug fix (2026-10-30, user-reported): same back-button fix as
  // login_screen.dart — see that screen's doc comment for the full
  // explanation, including the 22 Nov /welcome update.
  void _onBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/welcome');
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

  /// Finds `createAccountPrivacyLinkLabel`/`createAccountTermsLinkLabel`
  /// as literal substrings inside `createAccountConsentText` and makes
  /// just those two words tappable, rather than storing the sentence
  /// pre-split into prefix/middle/suffix keys. A translator only ever has
  /// to write one natural sentence per language (the PDF's own Urdu
  /// already reads naturally this way, words in normal RTL order) instead
  /// of three fragments that would have to be re-ordered by hand for
  /// Urdu's different word order.
  Widget _buildConsentLine(AppLocalizations l10n) {
    final text = l10n.createAccountConsentText;
    final privacyLabel = l10n.createAccountPrivacyLinkLabel;
    final termsLabel = l10n.createAccountTermsLinkLabel;
    final baseStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: HumsafarColors.muted) ??
        const TextStyle(fontSize: 12, color: HumsafarColors.muted);
    final linkStyle = baseStyle.copyWith(
      color: HumsafarColors.primaryDark,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );

    final privacyIndex = text.indexOf(privacyLabel);
    final termsIndex = text.indexOf(termsLabel, privacyIndex >= 0 ? privacyIndex + privacyLabel.length : 0);

    // Fallback: if a future translation re-words the sentence so it no
    // longer literally contains both link labels, fall back to plain
    // text rather than risk a bad substring split — the two screens are
    // still one tap away from the app bar elsewhere if this ever
    // triggers; it only costs the inline convenience, not access.
    if (privacyIndex < 0 || termsIndex < 0) {
      return Text(text, style: baseStyle);
    }

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: text.substring(0, privacyIndex)),
          TextSpan(text: privacyLabel, style: linkStyle, recognizer: _privacyLinkRecognizer),
          TextSpan(text: text.substring(privacyIndex + privacyLabel.length, termsIndex)),
          TextSpan(text: termsLabel, style: linkStyle, recognizer: _termsLinkRecognizer),
          TextSpan(text: text.substring(termsIndex + termsLabel.length)),
        ],
      ),
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
              // Bug fix (UI-22, Sarim's 1.9.5 design-vs-app pass): this
              // role picker used to sit right before the Register button,
              // after every text field — Sarim wants the role choice made
              // up front, not buried at the bottom. Moved here verbatim
              // (same widgets, same _hasInvite lock logic below), nothing
              // about the lock-to-Guardian behavior itself changed.
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
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.registerButton),
              ),
              const SizedBox(height: 12),
              // Bug fix (Sarim's 23 Nov Privacy/Terms spec, screen 03 v0.3):
              // one line under the button with "Privacy Policy" and "Terms"
              // as tappable links, opening the two new plain-text screens.
              // No consent tick box for the prototype — the spec is
              // explicit tapping Create account itself counts as agreeing.
              _buildConsentLine(l10n),
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
