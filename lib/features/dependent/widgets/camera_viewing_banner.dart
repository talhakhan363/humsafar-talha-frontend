import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';

/// Task 6.9's privacy-critical half (FR-K1.3): "the on-screen viewing
/// indicator is not optional polish — it must actually appear whenever a
/// Guardian is viewing" (Talha's handbook, Task 6.9's row). Mockup 29
/// ("Home with the camera viewing notice") puts this on Dependent Home,
/// always visible — not a dismissible toast, not gated behind opening a
/// menu — because a Dependent needs to know their camera is live *right
/// now*, not go looking for it.
///
/// Polls `GET /dependents/{id}/camera/viewing` (`camera_contract.md`)
/// every 15 seconds, same cadence as the Panic screen's own
/// `_refreshInterval` — frequent enough that "someone started watching"
/// shows up promptly, without hammering the backend. Renders nothing
/// (`SizedBox.shrink()`) whenever nobody is watching, so it adds no
/// visual weight to Home the rest of the time.
///
/// **Field-name fix, 2026-10-22 (real bug, found and reported by Sarim
/// against the real `camera_contract.md` on `dev`):** the first build of
/// this widget read `is_being_viewed`/`viewer_count`, guessed from a
/// written contract summary rather than the contract file itself — the
/// real response is `{"being_viewed": bool, "viewers":
/// [{"user_id", "full_name", "role", "since"}]}`. As built, this meant
/// the banner would NEVER have appeared on a real Dependent's phone —
/// `is_being_viewed` is always absent, so it always decoded to `false`.
/// Confirmed Critical for 6.12 K-02. Fixed below: reads `being_viewed`
/// directly, and the viewer count is `viewers.length` rather than a
/// separate count field (the contract has no standalone count — the
/// list itself is the source of truth). `full_name`/`role`/`since` per
/// viewer are not yet surfaced in the UI (this banner only ever showed a
/// count, never names) — a possible future enhancement, not a gap
/// against what this banner already did before the fix.
///
/// On a fetch error (offline, token expired, anything) this fails
/// quietly and tries again on the next poll, same reasoning as
/// `DependentHomeScreen._loadUnreadMessages()` — a transient failure
/// should never make this banner either wrongly claim or wrongly hide
/// that someone is watching; it just waits for the next successful read.
class CameraViewingBanner extends ConsumerStatefulWidget {
  const CameraViewingBanner({super.key, required this.dependentId});

  final String dependentId;

  @override
  ConsumerState<CameraViewingBanner> createState() => _CameraViewingBannerState();
}

class _CameraViewingBannerState extends ConsumerState<CameraViewingBanner> {
  static const _pollInterval = Duration(seconds: 15);

  Timer? _timer;
  bool _isBeingViewed = false;
  int? _viewerCount;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(_pollInterval, (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final response = await ref
          .read(apiClientProvider)
          .get<Map<String, dynamic>>('/dependents/${widget.dependentId}/camera/viewing');
      if (!mounted) return;
      final viewers = response.data?['viewers'] as List<dynamic>?;
      setState(() {
        _isBeingViewed = (response.data?['being_viewed'] as bool?) ?? false;
        _viewerCount = viewers?.length;
      });
    } on ApiException {
      // Quiet failure — see the class doc comment above.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isBeingViewed) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      color: Colors.teal.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.visibility, color: Colors.teal, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _viewerCount != null && _viewerCount! > 1
                  ? '${l10n.cameraBeingViewedBanner} (${l10n.cameraViewerCountLabel(_viewerCount!)})'
                  : l10n.cameraBeingViewedBanner,
              style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
