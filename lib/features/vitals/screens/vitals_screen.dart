import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/formatting/format_helpers.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/theme/humsafar_colors.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/export_scope_sheet.dart';
import '../../../shared/widgets/language_switch_button.dart';

const _manualMetrics = ['blood_pressure', 'blood_sugar', 'spo2', 'temperature'];
const _allMetrics = ['blood_pressure', 'blood_sugar', 'spo2', 'temperature', 'heart_rate'];

String metricLabel(AppLocalizations l10n, String metric) {
  switch (metric) {
    case 'blood_pressure':
      return l10n.metricBloodPressure;
    case 'blood_sugar':
      return l10n.metricBloodSugar;
    case 'spo2':
      return l10n.metricSpo2;
    case 'temperature':
      return l10n.metricTemperature;
    case 'heart_rate':
      return l10n.metricHeartRate;
    default:
      return metric;
  }
}

/// Reading-object -> one display line, shared by the latest tiles and
/// the history list below. `vitals_contract.md` is explicit there is
/// no high/low/normal judgement — this only ever shows the number.
String _valueLine(Map<String, dynamic>? reading) {
  if (reading == null) return '—';
  final metric = reading['metric_type'] as String?;
  final value = reading['value'];
  if (metric == 'blood_pressure') return '$value/${reading['diastolic']} ${reading['unit'] ?? 'mmHg'}';
  return '$value ${reading['unit'] ?? ''}'.trim();
}

/// Tasks 5.7 — mockups 26/28 "Vitals"/"My health", grounded in
/// `vitals_contract.md`. Latest-value tiles for all five metrics (the
/// four typeable ones plus `heart_rate`, shown read-only as
/// band-sourced — `AddVitalReadingScreen` never offers it, matching
/// the contract's own 422 if a client tried), then a chronological
/// list with a metric filter and delete (`can_delete`).
///
/// Serves both roles from one screen (role-neutral route, same shape
/// as `/messages`/`/records`): a Guardian opens it with a linked
/// Dependent's id, the Dependent opens it with their own.
///
/// **Named scope cut:** no charts/trend lines — `vitals_contract.md`
/// itself says there is no high/low/normal judgement on screen, and a
/// trend visualization is a design call nothing in this task's own
/// wording ("vitals entry UI") asked for; flagged rather than built
/// small, same reasoning as every other named cut this batch.
class VitalsScreen extends ConsumerStatefulWidget {
  const VitalsScreen({super.key, required this.dependentId});

  final String dependentId;

  @override
  ConsumerState<VitalsScreen> createState() => _VitalsScreenState();
}

class _VitalsScreenState extends ConsumerState<VitalsScreen> {
  Map<String, dynamic>? _latest;
  List<Map<String, dynamic>> _history = [];
  String? _metricFilter;
  bool _isLoading = true;
  String? _loadError;
  final Set<String> _pendingDelete = {};

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
      final apiClient = ref.read(apiClientProvider);
      final latestResponse = await apiClient.get<Map<String, dynamic>>('/dependents/${widget.dependentId}/vitals/latest');
      final historyResponse = await apiClient.get<Map<String, dynamic>>(
        '/dependents/${widget.dependentId}/vitals',
        queryParameters: {if (_metricFilter != null) 'metric_type': _metricFilter},
      );
      if (!mounted) return;
      setState(() {
        _latest = latestResponse.data?['latest'] as Map<String, dynamic>?;
        _history = (historyResponse.data?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = _messageFor(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _messageFor(ApiException e) {
    final l10n = AppLocalizations.of(context)!;
    if (e.code == 'MODULE_ACCESS_DENIED') return l10n.healthRecordsAccessDeniedMessage;
    return e.message;
  }

  Future<void> _delete(Map<String, dynamic> reading) async {
    final readingId = reading['reading_id'] as String;
    setState(() => _pendingDelete.add(readingId));
    try {
      await ref.read(apiClientProvider).delete('/dependents/${widget.dependentId}/vitals/$readingId');
      if (!mounted) return;
      setState(() => _history.removeWhere((r) => r['reading_id'] == readingId));
      _load(); // refresh the latest tiles too, in case the deleted reading was the newest
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _pendingDelete.remove(readingId));
    }
  }

  Future<void> _openAdd() async {
    final added = await context.push<bool>('/vitals/add', extra: widget.dependentId);
    if (added == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.vitalsScreenTitle),
        actions: [
          const LanguageSwitchButton(),
          const AccessibilityToggleButton(),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: l10n.exportButtonLabel,
            onPressed: () => showExportScopeSheet(
              context: context,
              ref: ref,
              exportPath: '/dependents/${widget.dependentId}/vitals/export',
              fileNamePrefix: 'vitals',
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _openAdd, child: const Icon(Icons.add)),
      // Bug fix (2026-10-30, found live by the user): bottom content was
      // getting hidden behind the phone's 3-button nav bar on scroll, same
      // root cause as dependent_home_screen.dart's earlier fix — body
      // wasn't safe-area-aware at the bottom. SafeArea(top: false) avoids
      // double-padding the top (the AppBar already handles that).
      body: SafeArea(bottom: true, top: false, child: RefreshIndicator(onRefresh: _load, child: _buildBody(l10n))),
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
    final languageCode = Localizations.localeOf(context).languageCode;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allMetrics.map((metric) {
            final reading = _latest?[metric] as Map<String, dynamic>?;
            return SizedBox(
              width: 150,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(metricLabel(l10n, metric), style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(_valueLine(reading), style: Theme.of(context).textTheme.titleMedium),
                      if (metric == 'heart_rate')
                        Text(l10n.fromBandNote, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: HumsafarColors.muted)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text(l10n.vitalsHistoryHeader, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(l10n, null, l10n.recordCategoryAll),
              for (final metric in _manualMetrics) _buildFilterChip(l10n, metric, metricLabel(l10n, metric)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(l10n.noVitalsReadingsMessage, textAlign: TextAlign.center),
          )
        else
          ..._history.map((reading) {
            final readingId = reading['reading_id'] as String;
            final canDelete = reading['can_delete'] as bool? ?? false;
            final recordedAt = DateTime.tryParse(reading['recorded_at'] as String? ?? '')?.toLocal();
            final isBand = reading['source'] == 'wearable';
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(isBand ? Icons.watch_outlined : Icons.edit_note),
                title: Text('${metricLabel(l10n, reading['metric_type'] as String? ?? '')} · ${_valueLine(reading)}'),
                subtitle: Text(recordedAt == null ? '' : formatDateDisplay(recordedAt, languageCode)),
                trailing: canDelete
                    ? (_pendingDelete.contains(readingId)
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(reading)))
                    : null,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildFilterChip(AppLocalizations l10n, String? metric, String label) {
    final selected = _metricFilter == metric;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _metricFilter = metric);
          _load();
        },
      ),
    );
  }
}
