import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/accessibility_mode.dart';
import '../../core/theme/accessibility_mode_provider.dart';

/// Task 1.9 — a small always-visible toggle so every screen can flip
/// between standard and high-contrast/large-text mode during development.
/// Once a real Settings screen exists, this control moves there; for now
/// it lives in each home screen's AppBar so it's trivial to test.
///
/// NOTE: the `flutter_gen/gen_l10n/...` import below only resolves after
/// Task 1.10's localization scaffold is in place and `flutter pub get`
/// has been run once. If you're doing 1.9 in isolation before 1.10, use
/// the plain-English tooltip strings shown in that commit instead — see
/// the walkthrough for the exact two versions of this file.
class AccessibilityToggleButton extends ConsumerWidget {
  const AccessibilityToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(accessibilityModeProvider);
    final isHighContrast = mode == AccessibilityMode.highContrast;
    final l10n = AppLocalizations.of(context)!;

    return IconButton(
      icon: Icon(isHighContrast ? Icons.contrast : Icons.contrast_outlined),
      tooltip: isHighContrast
          ? l10n.switchToStandardView
          : l10n.switchToAccessibleView,
      onPressed: () => ref.read(accessibilityModeProvider.notifier).toggle(),
    );
  }
}
