import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/auth/current_user_provider.dart';
import '../../../core/location/device_location_source.dart';
import '../../../core/location/location_polling_service.dart';
import '../../../core/network/providers.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';
import '../widgets/location_status_banner.dart';

/// Task 2.7 wires the background location service into this screen's
/// lifecycle: starts polling when the Dependent is on this screen and the
/// app is in the foreground, stops when they navigate away or the app is
/// backgrounded (WidgetsBindingObserver below) — see
/// LocationPollingService's doc comment for why this is scoped to
/// foreground-only rather than a true background service.
///
/// Still a placeholder otherwise — Task 3.10 replaces the body below with
/// the real Dependent Mode home (Panic/Wellness/Medication). When 3.10
/// lands, move the service start/stop calls into its initState/dispose
/// instead of deleting them here; don't let the location service quietly
/// disappear when this placeholder is replaced.
///
/// Not automated-tested as a full screen: `_startLocationSharing` calls
/// through to the real Geolocator plugin by default, which has no
/// platform channel under `flutter test` and would throw
/// MissingPluginException. The parts that can be tested without a device
/// — LocationPollingService's polling/retry logic and
/// LocationStatusBanner's per-status rendering — are split out and have
/// their own widget/unit tests. The rest (does the OS permission dialog
/// actually appear, does a real GPS fix come back) is a manual check —
/// see test_cases/TEST_CASE_LOG.md.
class DependentHomeScreen extends ConsumerStatefulWidget {
  const DependentHomeScreen({super.key});

  @override
  ConsumerState<DependentHomeScreen> createState() => _DependentHomeScreenState();
}

class _DependentHomeScreenState extends ConsumerState<DependentHomeScreen> with WidgetsBindingObserver {
  LocationPollingService? _locationService;
  LocationPermissionStatus? _permissionStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startLocationSharing();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationService?.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only poll while the app is actually in the foreground — see the
    // class doc comment on why this doesn't try to run in the background.
    if (state == AppLifecycleState.resumed) {
      _startLocationSharing();
    } else {
      _locationService?.stop();
    }
  }

  Future<void> _startLocationSharing() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    _locationService ??= LocationPollingService(apiClient: ref.read(apiClientProvider), dependentId: user.userId);
    final status = await _locationService!.start();
    if (!mounted) return;
    setState(() => _permissionStatus = status);
  }

  void _openSettings() {
    if (_permissionStatus == LocationPermissionStatus.serviceDisabled) {
      unawaited(Geolocator.openLocationSettings());
    } else {
      unawaited(Geolocator.openAppSettings());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dependentAppTitle),
        actions: [
          const LanguageSwitchButton(),
          const AccessibilityToggleButton(),
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: l10n.switchModeTooltip,
            onPressed: () => context.go('/role-select'),
          ),
        ],
      ),
      body: Column(
        children: [
          LocationStatusBanner(
            status: _permissionStatus,
            onRetry: _startLocationSharing,
            onOpenSettings: _openSettings,
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(l10n.dependentHomePlaceholder, textAlign: TextAlign.center),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
