import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humsafar_frontend/features/dependent/screens/coming_soon_screen.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

/// TC-3.10-14 — widget test for ComingSoonScreen (Task 3.10). Pure
/// widget: no ApiClient, no plugin, no device.
///
/// Updated 2026-10-20 (Tasks 3.11/3.12): `ComingSoonKind` dropped `panic`
/// and `wellnessCheck` once their real screens shipped — only
/// `medication` is left, waiting on Task 3.13. See the enum's doc
/// comment in coming_soon_screen.dart.
Widget _wrap(ComingSoonKind kind) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ComingSoonScreen(kind: kind),
    );

void main() {
  testWidgets('TC-3.10-14: shows the right title and "coming in Task 3.13" message', (tester) async {
    await tester.pumpWidget(_wrap(ComingSoonKind.medication));
    expect(find.text('My medicine'), findsOneWidget);
    expect(find.text('Medication confirmation is coming in Task 3.13.'), findsOneWidget);
  });
}
