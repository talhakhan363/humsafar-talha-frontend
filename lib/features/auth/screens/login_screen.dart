import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// Task 1.11 — static login screen. UI only, dummy data.
///
/// There's no real backend yet, so a "successful" submit here can't
/// actually know whether this user is a Guardian or a Dependent — that
/// comes from the JWT once Task 1.3 (Auth API) + Task 2.5 (real wiring)
/// land. Until then, submitting routes to the dev role-select screen as a
/// stand-in for "here's your account" — Task 2.5 replaces this with a
/// real role-based redirect and deletes the dev screen entirely.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // Dummy data only — Task 1.11 scope. Real login happens once Task 1.3
    // (Auth API) is wired in at Task 2.5, and will redirect by actual role.
    context.go('/role-select');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.loginScreenTitle),
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
                controller: _identifierController,
                decoration: InputDecoration(labelText: l10n.emailLabel),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.fieldRequiredError
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.passwordLabel),
                validator: (value) => (value == null || value.isEmpty)
                    ? l10n.fieldRequiredError
                    : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: Text(l10n.loginButton),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/register'),
                child: Text(l10n.dontHaveAccountPrompt),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
