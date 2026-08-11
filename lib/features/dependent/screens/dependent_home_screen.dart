import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

class DependentHomeScreen extends StatelessWidget {
  const DependentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dependentAppTitle),
        actions: [
          const LanguageSwitchButton(),
          const AccessibilityToggleButton(),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: l10n.switchModeTooltip,
            onPressed: () => context.go('/role-select'),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            l10n.dependentHomePlaceholder,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
