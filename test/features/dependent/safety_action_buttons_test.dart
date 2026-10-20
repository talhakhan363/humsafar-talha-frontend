import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humsafar_frontend/features/dependent/widgets/safety_action_buttons.dart';

/// TC-3.10-11..13 — widget tests for PanicButton/SafetyActionButton
/// (Task 3.10). Pure widgets: no l10n, no plugin, no device needed —
/// they take already-resolved label/subtitle strings.
void main() {
  testWidgets('TC-3.10-11: PanicButton shows its label/subtitle and calls onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PanicButton(onTap: () => tapped = true, label: 'PANIC', subtitle: 'Press for help'),
      ),
    ));

    expect(find.text('PANIC'), findsOneWidget);
    expect(find.text('Press for help'), findsOneWidget);

    await tester.tap(find.text('PANIC'));
    expect(tapped, isTrue);
  });

  testWidgets('TC-3.10-12: SafetyActionButton shows its label/subtitle and calls onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SafetyActionButton(onTap: () => tapped = true, label: 'I am OK', subtitle: 'Next check: 2:00 PM'),
      ),
    ));

    expect(find.text('I am OK'), findsOneWidget);
    expect(find.text('Next check: 2:00 PM'), findsOneWidget);

    await tester.tap(find.text('I am OK'));
    expect(tapped, isTrue);
  });

  testWidgets('TC-3.10-13: button text scales up under the large-text theme instead of staying fixed', (tester) async {
    double? themeSize;

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(textTheme: const TextTheme(titleLarge: TextStyle(fontSize: 31))),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            themeSize = Theme.of(context).textTheme.titleLarge?.fontSize;
            return SafetyActionButton(onTap: () {}, label: 'I am OK', subtitle: 'sub');
          },
        ),
      ),
    ));

    final buttonSize = tester.widget<Text>(find.text('I am OK')).style?.fontSize;

    expect(buttonSize, isNotNull);
    expect(buttonSize, themeSize);
  });
}
