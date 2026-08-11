import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../providers/app_mode_provider.dart';
import '../../../shared/widgets/language_switch_button.dart';

// TEMPORARY, DEV-ONLY. Deleted once real login (Task 1.11 / 2.5) lands.
//
// Task 1.11 note: the two "Preview" links at the bottom are also
// temporary — they exist so the new static Register/Login screens are
// reachable for testing before they become the app's actual entry point
// (that swap-over happens at Task 2.5, when this whole screen is deleted).
class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
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
                style: const TextStyle(color: Colors.grey),
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
              onPressed: () => context.go('/login'),
              child: Text(l10n.previewLoginLink),
            ),
            TextButton(
              onPressed: () => context.go('/register'),
              child: Text(l10n.previewRegisterLink),
            ),
          ],
        ),
      ),
    );
  }
}
