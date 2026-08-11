import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_locale_provider.dart';

/// Task 1.10 — lets the user explicitly pick English or Urdu instead of
/// only following the phone's system language.
class LanguageSwitchButton extends ConsumerWidget {
  const LanguageSwitchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chosenLocale = ref.watch(appLocaleProvider);
    final activeCode =
        (chosenLocale ?? Localizations.localeOf(context)).languageCode;

    return PopupMenuButton<String>(
      tooltip: 'Change language',
      icon: const Icon(Icons.language),
      onSelected: (code) =>
          ref.read(appLocaleProvider.notifier).setLocale(Locale(code)),
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: 'en',
          checked: activeCode == 'en',
          child: const Text('English'),
        ),
        CheckedPopupMenuItem(
          value: 'ur',
          checked: activeCode == 'ur',
          child: const Text('اردو'),
        ),
      ],
    );
  }
}
