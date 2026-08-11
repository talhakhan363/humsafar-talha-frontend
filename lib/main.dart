import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import 'core/localization/app_locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/accessibility_mode_provider.dart';
import 'core/theme/app_theme.dart';

// Wrapping the whole app in ProviderScope is what makes Riverpod state
// available everywhere below it.
void main() {
  runApp(
    const ProviderScope(
      child: HumsafarApp(),
    ),
  );
}

class HumsafarApp extends ConsumerWidget {
  const HumsafarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final accessibilityMode = ref.watch(accessibilityModeProvider);
    final chosenLocale = ref.watch(appLocaleProvider);

    return MaterialApp.router(
      title: 'Humsafar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeFor(accessibilityMode),
      routerConfig: router,
      // Task 1.10 — localization scaffold.
      locale: chosenLocale, // null = follow the phone's system language
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
