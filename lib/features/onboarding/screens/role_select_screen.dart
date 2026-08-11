import 'package:flutter/material.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/app_mode_provider.dart';

// TEMPORARY, DEV-ONLY. Deleted once real login (Task 1.11 / 2.5) lands.
class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.devRoleSwitcherTitle)),
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
          ],
        ),
      ),
    );
  }
}
