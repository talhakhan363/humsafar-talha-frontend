import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';

/// Task 5.8 — mockup 27 "My band" (+ 26c "Band not sending" folded in
/// as a status variant, not a separate screen/route — a `no_data`
/// status is just one more value this screen already renders, not a
/// distinct flow, same "don't build a second screen for one state"
/// reasoning as `alerts_screen.dart`'s tab split). Grounded in
/// `wearable_contract.md`.
///
/// Status comes straight from `GET /dependents/{id}/wearable` — the
/// contract computes `status` from the clock at request time, so this
/// screen never has to guess it client-side. The "Generate demo data"
/// button (`POST .../wearable/mock`) exists because the real band
/// (Task 5.5) isn't built yet, exactly per the handbook's own
/// instruction not to block this screen on the purchase.
class MyBandScreen extends ConsumerStatefulWidget {
  const MyBandScreen({super.key, required this.dependentId});

  final String dependentId;

  @override
  ConsumerState<MyBandScreen> createState() => _MyBandScreenState();
}

class _MyBandScreenState extends ConsumerState<MyBandScreen> {
  Map<String, dynamic>? _status;
  bool _isLoading = true;
  String? _loadError;
  bool _isActing = false;

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
      final response = await ref.read(apiClientProvider).get<Map<String, dynamic>>('/dependents/${widget.dependentId}/wearable');
      if (!mounted) return;
      setState(() => _status = response.data);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.code == 'MODULE_ACCESS_DENIED'
          ? AppLocalizations.of(context)!.healthRecordsAccessDeniedMessage
          : e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateDemoData() async {
    setState(() => _isActing = true);
    try {
      await ref.read(apiClientProvider).post('/dependents/${widget.dependentId}/wearable/mock');
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.code == 'NOT_FOUND' ? l10n.demoDataDisabledMessage : e.message)));
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _unpair() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unpairBandConfirmTitle),
        content: Text(l10n.unpairBandConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancelButton)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.unpairButtonLabel)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isActing = true);
    try {
      await ref.read(apiClientProvider).delete('/dependents/${widget.dependentId}/wearable');
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'not_paired':
        return l10n.bandStatusNotPaired;
      case 'waiting_for_first_data':
        return l10n.bandStatusWaitingForFirstData;
      case 'receiving':
        return l10n.bandStatusReceiving;
      case 'no_data':
        return l10n.bandStatusNoData;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myBandScreenTitle),
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
    final status = _status?['status'] as String? ?? 'not_paired';
    final device = _status?['device'] as Map<String, dynamic>?;
    final latestHr = _status?['latest_heart_rate'] as Map<String, dynamic>?;
    final isPaired = status != 'not_paired';

    if (!isPaired) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.watch_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(l10n.bandStatusNotPaired, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.push('/wearable/connect', extra: widget.dependentId).then((_) => _load()),
                icon: const Icon(Icons.bluetooth),
                label: Text(l10n.connectBandButtonLabel),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (status == 'no_data')
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_outlined, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.bandNoDataBanner)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device?['name'] as String? ?? l10n.myBandScreenTitle, style: Theme.of(context).textTheme.titleMedium),
                Text(device?['ble_address'] as String? ?? '', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Text('${l10n.bandStatusLabel}: ${_statusLabel(l10n, status)}'),
                const SizedBox(height: 4),
                Text('${l10n.latestHeartRateLabel}: ${latestHr == null ? '—' : '${latestHr['value']} bpm'}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _isActing ? null : _generateDemoData,
          icon: const Icon(Icons.auto_awesome),
          label: Text(l10n.generateDemoDataButtonLabel),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isActing ? null : _unpair,
          icon: const Icon(Icons.link_off),
          label: Text(l10n.unpairButtonLabel),
        ),
      ],
    );
  }
}
