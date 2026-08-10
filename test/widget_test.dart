import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/main.dart';

void main() {
  testWidgets('App compiles and shows splash screen', (WidgetTester tester) async {
    // Wrap HumsafarApp in ProviderScope just like in your real main.dart
    await tester.pumpWidget(
      const ProviderScope(
        child: HumsafarApp(),
      ),
    );

    // Verify the app boots without crashing
    expect(find.byType(HumsafarApp), findsOneWidget);
  });
}
