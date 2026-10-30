import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/theme/humsafar_colors.dart';
import '../../../providers/app_mode_provider.dart';
import '../../../shared/widgets/language_switch_button.dart';

// TEMPORARY, DEV-ONLY. Deleted once real login (Task 1.11 / 2.5) lands.
//
// Task 1.11 note: the two "Preview" links at the bottom are also
// temporary — they exist so the new static Register/Login screens are
// reachable for testing before they become the app's actual entry point
// (that swap-over happens at Task 2.5, when this whole screen is deleted).
//
// Bug fix (2026-10-30, user-reported): this screen is the app's real
// root whenever nobody's logged in (splash_screen.dart's `_checkSession`
// lands here with `context.go('/role-select')`, which replaces the whole
// go_router stack — same reasoning as every other `.go()` in this app).
// The two Preview links below used to also be `context.go(...)`, which
// replaced this screen out of the stack entirely, so the system back
// button from Login/Register had nothing left to pop and exited the app
// directly, skipping this screen. Changed to `context.push(...)` so this
// screen stays underneath and back naturally returns here — see
// login_screen.dart / register_screen.dart for the matching half of this
// fix (their own PopScope falls back to `/role-select` on the rare path
// where they're reached via `.go()` instead, e.g. straight after
// logout). Also added: pressing back on *this* screen (nothing left
// below it) now asks for confirmation before actually exiting the app,
// instead of exiting immediately.
class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  Future<void> _confirmExit(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.exitAppConfirmTitle),
        content: Text(l10n.exitAppConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancelButton)),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.exitAppButtonLabel)),
        ],
      ),
    );
    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmExit(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.devRoleSwitcherTitle),
          actions: const [LanguageSwitchButton()],
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  l10n.devRoleSwitcherBody,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: HumsafarColors.muted),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.read(appModeProvider.notifier).state = AppMode.guardian;
                  context.go('/guardian');
                },
                child: Text(l10n.continueAsGuardian),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  ref.read(appModeProvider.notifier).state = AppMode.dependent;
                  context.go('/dependent');
                },
                child: Text(l10n.continueAsDependent),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.push('/login'),
                child: Text(l10n.previewLoginLink),
              ),
              TextButton(
                onPressed: () => context.push('/register'),
                child: Text(l10n.previewRegisterLink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
