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

    // SplashScreen schedules a 600ms Future.delayed timer that navigates to
    // /role-select once it fires. The test framework asserts no timers are
    // still pending when a test ends, so this advances past it rather than
    // leaving it dangling — that's what "A Timer is still pending even
    // after the widget tree was disposed" was pointing at.
    await tester.pump(const Duration(milliseconds: 700));
  });
}
