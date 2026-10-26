import 'package:flutter/material.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/location/device_location_source.dart';
import '../../../core/theme/humsafar_colors.dart';

/// Small status row shown on the Dependent home screen for Task 2.7.
/// Deliberately a pure presentational widget — it takes the
/// already-resolved [LocationPermissionStatus] (or null while still
/// checking) and renders the matching message/button, with no
/// Geolocator/ApiClient calls of its own. That split is what lets this
/// be widget-tested without touching the real location plugin (which
/// would throw under `flutter test` — see DependentHomeScreen's doc
/// comment for why the full screen isn't automated-tested the same way).
class LocationStatusBanner extends StatelessWidget {
  const LocationStatusBanner({
    super.key,
    required this.status,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final LocationPermissionStatus? status;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (status == null) {
      return const SizedBox(
        height: 36,
        child: Center(
          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    switch (status!) {
      case LocationPermissionStatus.granted:
        // Fixed 2026-10-25 — Design Handoff v1.0 fix #7: Colors.teal on
        // white was 3.67:1, below the 4.5:1 AA minimum (Sarim's NFR-08
        // check). The primary token gives 5.36:1.
        return Container(
          width: double.infinity,
          color: HumsafarColors.primaryTint,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: HumsafarColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(l10n.locationSharingActiveLabel, style: const TextStyle(color: HumsafarColors.primary)),
            ],
          ),
        );
      case LocationPermissionStatus.denied:
        return _bannerWithAction(
          context,
          message: l10n.locationPermissionNeededMessage,
          buttonLabel: l10n.grantLocationPermissionButton,
          onPressed: onRetry,
        );
      case LocationPermissionStatus.deniedForever:
        return _bannerWithAction(
          context,
          message: l10n.locationPermissionDeniedForeverMessage,
          buttonLabel: l10n.openSettingsButton,
          onPressed: onOpenSettings,
        );
      case LocationPermissionStatus.serviceDisabled:
        return _bannerWithAction(
          context,
          message: l10n.locationServiceDisabledMessage,
          buttonLabel: l10n.openSettingsButton,
          onPressed: onOpenSettings,
        );
    }
  }

  Widget _bannerWithAction(
    BuildContext context, {
    required String message,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    // Fix #2 (section 3): was Colors.amber.shade100 / Colors.amber.shade900
    // — now the handoff's warning tokens, same semantic meaning.
    return Container(
      width: double.infinity,
      color: HumsafarColors.warningTint,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(color: HumsafarColors.warning)),
          const SizedBox(height: 6),
          TextButton(onPressed: onPressed, child: Text(buttonLabel)),
        ],
      ),
    );
  }
}
