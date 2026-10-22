import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// Task 6.9 — Guardian-side camera screen (mockups 19/19c), built as the
/// UI-only slice Talha asked for: it exercises the real pairing/watch-
/// session lifecycle against `camera_contract.md`, but does NOT render
/// actual video. Real streaming needs ZegoCloud's Express/room-streaming
/// SDK — a different integration than the Call UIKit Task 4.1/4.4 chose
/// for voice/video calls — and the spare-phone publisher (mockup 29b,
/// Task 6.10) to even test against, neither of which exist yet. Same
/// reasoning Task 4.7 (calls) was kept as its own isolated, native-SDK
/// delivery rather than batched in: wiring the actual video renderer is
/// a follow-up task of its own once 6.10's hardware exists, not silently
/// skipped — named here rather than hidden.
///
/// **Field-name fix, 2026-10-22 (real bug, found and reported by Sarim
/// against the real `camera_contract.md` on `dev`):** this screen was
/// first built from a written contract summary, not the contract file
/// itself. The real shapes:
/// - `GET /dependents/{id}/camera` → `{"paired": bool, "online": bool,
///   "viewers_now": int, "max_viewers": int}` — NOT `{"status": ...}`.
/// - `GET /dependents/{id}/camera/stream` (start/renew a watch session)
///   → carries no viewer count at all; errors mapped below.
/// - `DELETE /dependents/{id}/camera/stream` (stop watching) — unchanged.
///
/// Fixed below: pairing is now a bool (`_isPaired`), not a string
/// status. Since `/camera/stream` doesn't return a viewer count, the
/// live count shown while watching is read from `GET /dependents/{id}/
/// camera`'s `viewers_now` instead — fetched once right after starting
/// to watch, then refreshed alongside each 30s session renewal. This
/// means the displayed count can lag the real one by up to the renew
/// interval, same as the renewal itself already could; named here as a
/// real but minor tradeoff, not silently assumed to be exact. `online`
/// and `max_viewers` are read but not yet surfaced in the UI — this
/// screen never showed either before the fix, so that's not a new gap.
///
/// If any of these shapes still don't match, only the methods below
/// need adjusting — the screen's states/tests don't depend on the exact
/// field names, just on what they decode to.
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key, required this.dependentId, required this.dependentLabel});

  final String dependentId;
  final String dependentLabel;

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  // "renew every 30 s" per the written contract summary of Task 6.3.
  static const _renewInterval = Duration(seconds: 30);

  bool _isLoadingPairing = true;
  String? _pairingLoadError;
  bool _isPaired = false;

  bool _isStartingOrStopping = false;
  bool _isWatching = false;
  String? _watchError;
  int? _viewerCount;
  Timer? _renewTimer;

  @override
  void initState() {
    super.initState();
    _loadPairingStatus();
  }

  @override
  void dispose() {
    _renewTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPairingStatus() async {
    setState(() {
      _isLoadingPairing = true;
      _pairingLoadError = null;
    });
    try {
      final response =
          await ref.read(apiClientProvider).get<Map<String, dynamic>>('/dependents/${widget.dependentId}/camera');
      if (!mounted) return;
      setState(() {
        _isPaired = (response.data?['paired'] as bool?) ?? false;
        _isLoadingPairing = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPairing = false;
        _pairingLoadError = e.message;
      });
    }
  }

  String _messageFor(ApiException e) {
    final l10n = AppLocalizations.of(context)!;
    switch (e.code) {
      case 'CAMERA_NOT_PAIRED':
        return l10n.cameraNotPairedMessage;
      case 'CAMERA_OFFLINE':
        return l10n.cameraOfflineError;
      case 'MODULE_ACCESS_DENIED':
        return l10n.moduleAccessDeniedCameraError;
      case 'MAX_VIEWERS_REACHED':
        return l10n.cameraMaxViewersError;
      default:
        return e.message;
    }
  }

  Future<void> _startWatching() async {
    setState(() {
      _isStartingOrStopping = true;
      _watchError = null;
    });
    try {
      await ref.read(apiClientProvider).get<Map<String, dynamic>>('/dependents/${widget.dependentId}/camera/stream');
      if (!mounted) return;
      setState(() => _isWatching = true);
      await _refreshViewerCount();
      _renewTimer = Timer.periodic(_renewInterval, (_) => _renewWatching());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _watchError = _messageFor(e));
    } finally {
      if (mounted) setState(() => _isStartingOrStopping = false);
    }
  }

  /// `/camera/stream` carries no viewer count (see the class doc
  /// comment's field-name fix) — the count shown while watching comes
  /// from this separate, best-effort read of the pairing-status
  /// endpoint's `viewers_now` instead.
  Future<void> _refreshViewerCount() async {
    try {
      final response =
          await ref.read(apiClientProvider).get<Map<String, dynamic>>('/dependents/${widget.dependentId}/camera');
      if (!mounted) return;
      setState(() => _viewerCount = response.data?['viewers_now'] as int?);
    } on ApiException {
      // best-effort — see doc comment above and _renewWatching below.
    }
  }

  /// Best-effort renewal — same "don't let a transient failure tear down
  /// a working session" reasoning as `CameraViewingBanner`'s poll. If the
  /// camera actually goes offline mid-watch, the next manual action
  /// (Stop, or reopening the screen) is what surfaces that, not a
  /// background timer silently kicking the Guardian out.
  Future<void> _renewWatching() async {
    try {
      await ref.read(apiClientProvider).get<Map<String, dynamic>>('/dependents/${widget.dependentId}/camera/stream');
    } on ApiException {
      // best-effort, see doc comment above
    }
    await _refreshViewerCount();
  }

  Future<void> _stopWatching() async {
    _renewTimer?.cancel();
    _renewTimer = null;
    setState(() => _isStartingOrStopping = true);
    try {
      await ref.read(apiClientProvider).delete('/dependents/${widget.dependentId}/camera/stream');
    } on ApiException {
      // Leaving either way — see _renewWatching's reasoning.
    } finally {
      if (mounted) {
        setState(() {
          _isWatching = false;
          _viewerCount = null;
          _isStartingOrStopping = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dependentLabel),
        actions: [
          const LanguageSwitchButton(),
          const AccessibilityToggleButton(),
          IconButton(
            icon: const Icon(Icons.video_library_outlined),
            tooltip: l10n.savedClipsButtonLabel,
            onPressed: () => context.push('/guardian/camera/clips', extra: widget.dependentId),
          ),
        ],
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoadingPairing) return const Center(child: CircularProgressIndicator());
    if (_pairingLoadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_pairingLoadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadPairingStatus, child: Text(l10n.retryButton)),
            ],
          ),
        ),
      );
    }
    if (!_isPaired) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off_outlined, size: 48, color: Colors.grey.shade600),
              const SizedBox(height: 12),
              Text(l10n.cameraNotPairedMessage, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_watchError != null)
          Container(
            width: double.infinity,
            color: Colors.amber.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(_watchError!, style: TextStyle(color: Colors.amber.shade900)),
          ),
        Expanded(child: _isWatching ? _buildWatching(l10n) : _buildStartPrompt(l10n)),
      ],
    );
  }

  Widget _buildStartPrompt(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            _isStartingOrStopping
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _startWatching,
                    icon: const Icon(Icons.play_circle_outline),
                    label: Text(l10n.startWatchingButtonLabel),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatching(AppLocalizations l10n) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            color: Colors.black87,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.videocam, color: Colors.white54, size: 48),
                const SizedBox(height: 12),
                Text(
                  l10n.cameraWatchingPlaceholderMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                if (_viewerCount != null) ...[
                  const SizedBox(height: 12),
                  Text(l10n.cameraViewerCountLabel(_viewerCount!), style: const TextStyle(color: Colors.white)),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isStartingOrStopping
              ? const CircularProgressIndicator()
              : OutlinedButton.icon(
                  onPressed: _stopWatching,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: Text(l10n.stopWatchingButtonLabel),
                ),
        ),
      ],
    );
  }
}
