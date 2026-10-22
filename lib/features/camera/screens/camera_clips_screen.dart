import 'dart:typed_data';

import 'package:dio/dio.dart' show ResponseType;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/files/file_providers.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// Task 6.9 — Saved clips list (mockup 19b), the Guardian-side half of
/// Task 6.4's event-triggered clip capture. A clip is created
/// server-side when Panic Mode or the Remote Alarm fires with a camera
/// paired; this screen only lists/downloads/deletes what's already
/// there — it never triggers a recording itself.
///
/// Download reuses the exact pattern `medical_vault_screen.dart`
/// established for the records PDF export: fetch the clip's bytes with
/// `ApiClient.get<List<int>>(..., responseType: ResponseType.bytes)`,
/// then hand them to the OS share sheet via `ShareSource.shareBytes`
/// rather than building an in-app video player — same named scope cut
/// as that screen's own PDF/image viewer decision, for the same reason
/// (not this batch's job, and the OS's own video app already does it).
///
/// **Named field-name caveat:** same as `camera_screen.dart` — built
/// from the written summary of the clips section of `camera_contract.md`
/// (list / one / download / delete, `missed` after 3 minutes), not a
/// fresh read of the file itself. Assumed shape per clip:
/// `{"clip_id", "trigger": "panic"|"alarm", "status":
/// "uploaded"|"pending"|"missed", "created_at"}`.
class CameraClipsScreen extends ConsumerStatefulWidget {
  const CameraClipsScreen({super.key, required this.dependentId});

  final String dependentId;

  @override
  ConsumerState<CameraClipsScreen> createState() => _CameraClipsScreenState();
}

class _CameraClipsScreenState extends ConsumerState<CameraClipsScreen> {
  List<Map<String, dynamic>> _clips = [];
  bool _isLoading = true;
  String? _loadError;
  final Set<String> _pendingAction = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final response = await ref
          .read(apiClientProvider)
          .get<Map<String, dynamic>>('/dependents/${widget.dependentId}/camera/clips');
      if (!mounted) return;
      setState(() => _clips = (response.data?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _download(Map<String, dynamic> clip) async {
    final clipId = clip['clip_id'] as String;
    setState(() => _pendingAction.add(clipId));
    try {
      final response = await ref.read(apiClientProvider).get<List<int>>(
            '/dependents/${widget.dependentId}/camera/clips/$clipId/file',
            responseType: ResponseType.bytes,
          );
      final bytes = Uint8List.fromList(response.data ?? []);
      await ref.read(shareSourceProvider).shareBytes(bytes: bytes, fileName: 'humsafar_clip_$clipId.mp4');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _pendingAction.remove(clipId));
    }
  }

  Future<void> _delete(Map<String, dynamic> clip) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteClipConfirmTitle),
        content: Text(l10n.deleteClipConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancelButton)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.deleteButtonLabel)),
        ],
      ),
    );
    if (confirmed != true) return;

    final clipId = clip['clip_id'] as String;
    setState(() => _pendingAction.add(clipId));
    try {
      await ref.read(apiClientProvider).delete('/dependents/${widget.dependentId}/camera/clips/$clipId');
      if (!mounted) return;
      setState(() => _clips.removeWhere((c) => c['clip_id'] == clipId));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.clipDeletedConfirmation)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _pendingAction.remove(clipId));
    }
  }

  String _triggerLabel(AppLocalizations l10n, String? trigger) {
    switch (trigger) {
      case 'panic':
        return l10n.clipTriggerPanicLabel;
      case 'alarm':
        return l10n.clipTriggerAlarmLabel;
      default:
        return trigger ?? '';
    }
  }

  String _statusLabel(AppLocalizations l10n, String? status) {
    switch (status) {
      case 'uploaded':
        return l10n.clipStatusUploaded;
      case 'pending':
        return l10n.clipStatusPending;
      case 'missed':
        return l10n.clipStatusMissed;
      default:
        return status ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cameraClipsScreenTitle),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody(l10n)),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: Text(l10n.retryButton)),
            ],
          ),
        ),
      );
    }
    if (_clips.isEmpty) {
      return Center(child: Text(l10n.noSavedClipsMessage, textAlign: TextAlign.center));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _clips.map((clip) {
        final clipId = clip['clip_id'] as String? ?? '';
        final status = clip['status'] as String?;
        final isBusy = _pendingAction.contains(clipId);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(clip['trigger'] == 'panic' ? Icons.warning_amber_outlined : Icons.notifications_active_outlined),
            title: Text(_triggerLabel(l10n, clip['trigger'] as String?)),
            subtitle: Text(_statusLabel(l10n, status)),
            trailing: isBusy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : status == 'uploaded'
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.download_outlined),
                            tooltip: l10n.downloadClipButtonLabel,
                            onPressed: () => _download(clip),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: l10n.deleteClipButtonLabel,
                            onPressed: () => _delete(clip),
                          ),
                        ],
                      )
                    : null,
          ),
        );
      }).toList(),
    );
  }
}
