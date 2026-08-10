import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/app_mode_provider.dart';

// TEMPORARY, DEV-ONLY. Deleted once real login (Task 1.11 / 2.5) lands.
class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Humsafar — Dev Role Switcher')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Temporary screen — will be replaced by real login (Task 1.11 / 2.5).',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(appModeProvider.notifier).state = AppMode.guardian;
                context.go('/guardian');
              },
              child: const Text('Continue as Guardian'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                ref.read(appModeProvider.notifier).state = AppMode.dependent;
                context.go('/dependent');
              },
              child: const Text('Continue as Dependent'),
            ),
          ],
        ),
      ),
    );
  }
}
