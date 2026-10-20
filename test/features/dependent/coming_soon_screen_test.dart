import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humsafar_frontend/features/dependent/screens/coming_soon_screen.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

/// TC-3.10-14 — widget test for ComingSoonScreen (Task 3.10). Pure
/// widget: no ApiClient, no plugin, no device.
Widget _wrap(ComingSoonKind kind) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ComingSoonScreen(kind: kind),
    );

void main() {
  testWidgets('TC-3.10-14: each kind shows its own title and "coming in Task X" message', (tester) async {
    await tester.pumpWidget(_wrap(ComingSoonKind.panic));
    expect(find.text('PANIC'), findsOneWidget);
    expect(find.text('Panic Mode is coming in Task 3.11.'), findsOneWidget);

    await tester.pumpWidget(_wrap(ComingSoonKind.wellnessCheck));
    expect(find.text('I am OK'), findsOneWidget);
    expect(find.text('Wellness check response is coming in Task 3.12.'), findsOneWidget);

    await tester.pumpWidget(_wrap(ComingSoonKind.medication));
    expect(find.text('My medicine'), findsOneWidget);
    expect(find.text('Medication confirmation is coming in Task 3.13.'), findsOneWidget);
  });
}
