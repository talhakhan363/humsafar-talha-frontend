import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humsafar_frontend/core/location/device_location_source.dart';
import 'package:humsafar_frontend/features/dependent/widgets/location_status_banner.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

/// TC-2.7-06..08 — widget tests for LocationStatusBanner (Task 2.7). Pure
/// widget: no Geolocator/ApiClient calls, so no device/login needed.
Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('TC-2.7-06: granted shows the active label and no action button', (tester) async {
    await tester.pumpWidget(_wrap(LocationStatusBanner(
      status: LocationPermissionStatus.granted,
      onRetry: () {},
      onOpenSettings: () {},
    )));

    expect(find.text('Location sharing: Active'), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('TC-2.7-07: denied shows Grant Permission and calls onRetry when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(LocationStatusBanner(
      status: LocationPermissionStatus.denied,
      onRetry: () => tapped = true,
      onOpenSettings: () {},
    )));

    expect(find.text('Grant Permission'), findsOneWidget);
    await tester.tap(find.text('Grant Permission'));
    expect(tapped, isTrue);
  });

  testWidgets('TC-2.7-08: deniedForever and serviceDisabled both route to Open Settings', (tester) async {
    for (final status in [LocationPermissionStatus.deniedForever, LocationPermissionStatus.serviceDisabled]) {
      var opened = false;
      await tester.pumpWidget(_wrap(LocationStatusBanner(
        status: status,
        onRetry: () {},
        onOpenSettings: () => opened = true,
      )));

      expect(find.text('Open Settings'), findsOneWidget);
      await tester.tap(find.text('Open Settings'));
      expect(opened, isTrue);
    }
  });

  testWidgets('TC-2.7-09: null status (still checking) shows a small spinner, no text', (tester) async {
    await tester.pumpWidget(_wrap(LocationStatusBanner(
      status: null,
      onRetry: () {},
      onOpenSettings: () {},
    )));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
  });
}
