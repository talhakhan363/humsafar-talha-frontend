import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';
import '../../vitals/screens/vitals_screen.dart' show metricLabel;

const _vitalsMetricOrder = ['blood_pressure', 'blood_sugar', 'spo2', 'temperature', 'heart_rate'];
const _dayOptions = [7, 30, 90];

/// Task 7.3 — Guardian-side Analytics dashboard (mockup 16), grounded in
/// `analytics_contract.md`. One combined call
/// (`GET /dependents/{id}/analytics?days=`) drives both sections below —
/// per the written contract summary, a part the caller lacks permission
/// for comes back `null` rather than a `403`, so (unlike almost every
/// other screen in this app) permission is handled by checking for a
/// null section, not by catching `MODULE_ACCESS_DENIED`.
///
/// **Named field-name caveat (flagged for Abdullah/Talha to confirm,
/// same standing caveat as Task 6.9's `CameraScreen`/
/// `CameraViewingBanner`):** built from the written contract summary in
/// `Humsafar_Progress_Tracker.md` ("adherence: rate, per-day,
/// per-medicine, change against the previous period, streak" / "vitals:
/// min/max/average/latest/per-day/trend"), not a fresh read of
/// `analytics_contract.md` itself. Assumed response shape:
/// ```
/// {
///   "adherence": {
///     "rate": 0.92, "taken": 46, "missed": 4, "waiting": 2,
///     "streak_days": 5, "change_vs_previous_period": 0.03,
///     "per_day": [{"date": "YYYY-MM-DD", "taken": 2, "missed": 0, "waiting": 0}],
///     "per_medicine": [{"medicine_name": "Metformin", "rate": 0.95, "taken": 19, "missed": 1}]
///   } | null,
///   "vitals": {
///     "metrics": {
///       "<metric_type>": {
///         "count": 12,
///         "min"/"max"/"average"/"latest": {"value": 110, "diastolic": 70, "unit": "mmHg"},
///         "trend": "rising" | "falling" | "steady",
///         "per_day": [{"date": "YYYY-MM-DD", "value": 120, "diastolic": 80}]
///       }
///     }
///   } | null
/// }
/// ```
/// (the per-point `value`/`diastolic`/`unit` shape mirrors
/// `vitals_contract.md`'s own reading object, reused here rather than
/// invented fresh — `vitals_screen.dart`'s `_valueLine` does the same
/// "blood_pressure needs a second number" branch this screen's
/// `_pointValueLine` does.) If the real field names differ, only the
/// parsing in `_load()`/`_pointValueLine` below needs adjusting — the
/// screen's loading/empty/chart states don't depend on the exact names.
///
/// **Named scope cuts:** no export/PDF download here — that is Task
/// 7.2's `reports_contract.md` (scheduled/manual summary PDFs), which no
/// task in the roadmap assigns a frontend screen to yet; flagged rather
/// than silently folded in. Blood pressure's trend chart plots the
/// systolic (top) number only — a second line for diastolic is a
/// nice-to-have, not something the contract's field list requires.
/// Day-range chips re-fetch the whole combined call rather than
/// filtering client-side, matching every other filter in this app
/// (`vitals_screen.dart`'s metric chips, `medical_vault_screen.dart`'s
/// category filter).
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key, required this.dependentId, required this.dependentLabel});

  final String dependentId;
  final String dependentLabel;

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _days = 30;
  String _selectedVitalsMetric = 'blood_pressure';
  Map<String, dynamic>? _adherence;
  Map<String, dynamic>? _vitalsMetrics;
  bool _isLoading = true;
  String? _loadError;

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
      final response = await ref.read(apiClientProvider).get<Map<String, dynamic>>(
            '/dependents/${widget.dependentId}/analytics',
            queryParameters: {'days': _days},
          );
      if (!mounted) return;
      final data = response.data ?? <String, dynamic>{};
      setState(() {
        _adherence = data['adherence'] as Map<String, dynamic>?;
        _vitalsMetrics = (data['vitals'] as Map<String, dynamic>?)?['metrics'] as Map<String, dynamic>?;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectDays(int days) {
    if (days == _days) return;
    setState(() => _days = days);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.analyticsScreenTitle),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          children: _dayOptions.map((days) => _dayChip(l10n, days)).toList(),
        ),
        const SizedBox(height: 20),
        _buildAdherenceSection(l10n),
        const SizedBox(height: 24),
        _buildVitalsSection(l10n),
      ],
    );
  }

  Widget _dayChip(AppLocalizations l10n, int days) {
    final label = switch (days) {
      7 => l10n.analyticsDays7Label,
      90 => l10n.analyticsDays90Label,
      _ => l10n.analyticsDays30Label,
    };
    return ChoiceChip(label: Text(label), selected: _days == days, onSelected: (_) => _selectDays(days));
  }

  Widget _buildAdherenceSection(AppLocalizations l10n) {
    final adherence = _adherence;
    if (adherence == null) {
      return Card(
        child: Padding(padding: const EdgeInsets.all(16), child: Text(l10n.adherenceAccessDeniedMessage)),
      );
    }
    final rate = (adherence['rate'] as num?)?.toDouble();
    final taken = adherence['taken'] as int? ?? 0;
    final missed = adherence['missed'] as int? ?? 0;
    final waiting = adherence['waiting'] as int? ?? 0;
    final streakDays = adherence['streak_days'] as int? ?? 0;
    final change = (adherence['change_vs_previous_period'] as num?)?.toDouble();
    final perDay = (adherence['per_day'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final perMedicine = (adherence['per_medicine'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.adherenceSectionHeader, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                if (rate != null) Text('${l10n.adherenceRateLabel}: ${_formatPercent(rate)}'),
                Text('${l10n.adherenceTakenLabel}: $taken'),
                Text('${l10n.adherenceMissedLabel}: $missed'),
                Text('${l10n.adherenceWaitingLabel}: $waiting'),
              ],
            ),
            const SizedBox(height: 12),
            if (perDay.isEmpty)
              Text(l10n.noAdherenceDataMessage)
            else
              SizedBox(height: 140, child: _buildAdherenceChart(perDay)),
            const SizedBox(height: 8),
            Text(l10n.adherenceStreakLabel(streakDays)),
            if (change != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(change >= 0 ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
                  const SizedBox(width: 4),
                  Text('${l10n.adherenceChangeVsPreviousLabel}: ${_formatPercent(change.abs())}'),
                ],
              ),
            ],
            if (perMedicine.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(l10n.adherencePerMedicineHeader, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              ...perMedicine.map((medicine) {
                final name = medicine['medicine_name'] as String? ?? '';
                final medicineRate = (medicine['rate'] as num?)?.toDouble();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(medicineRate == null ? name : '$name · ${_formatPercent(medicineRate)}'),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceChart(List<Map<String, dynamic>> perDay) {
    final primary = Theme.of(context).colorScheme.primary;
    final missedColor = Colors.grey.shade400;
    return BarChart(
      BarChartData(
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true),
        barGroups: [
          for (var i = 0; i < perDay.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(toY: (perDay[i]['taken'] as num? ?? 0).toDouble(), color: primary, width: 6),
                BarChartRodData(toY: (perDay[i]['missed'] as num? ?? 0).toDouble(), color: missedColor, width: 6),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildVitalsSection(AppLocalizations l10n) {
    final metrics = _vitalsMetrics;
    if (metrics == null) {
      return Card(
        child: Padding(padding: const EdgeInsets.all(16), child: Text(l10n.vitalsAccessDeniedMessage)),
      );
    }
    final selected = _selectedVitalsMetric;
    final data = metrics[selected] as Map<String, dynamic>?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.vitalsSectionHeader, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _vitalsMetricOrder.map((metric) {
                return ChoiceChip(
                  label: Text(metricLabel(l10n, metric)),
                  selected: selected == metric,
                  onSelected: (_) => setState(() => _selectedVitalsMetric = metric),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            if (data == null)
              Text(l10n.noVitalsTrendDataMessage)
            else
              _buildVitalsMetricDetail(l10n, selected, data),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsMetricDetail(AppLocalizations l10n, String metric, Map<String, dynamic> data) {
    final count = data['count'] as int? ?? 0;
    final min = data['min'] as Map<String, dynamic>?;
    final max = data['max'] as Map<String, dynamic>?;
    final average = data['average'] as Map<String, dynamic>?;
    final latest = data['latest'] as Map<String, dynamic>?;
    final trend = data['trend'] as String?;
    final perDay = (data['per_day'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l10n.vitalsMetricCountLabel}: $count'),
        if (min != null) Text('${l10n.vitalsMinLabel}: ${_pointValueLine(metric, min)}'),
        if (max != null) Text('${l10n.vitalsMaxLabel}: ${_pointValueLine(metric, max)}'),
        if (average != null) Text('${l10n.vitalsAverageLabel}: ${_pointValueLine(metric, average)}'),
        if (latest != null) Text('${l10n.vitalsLatestLabel}: ${_pointValueLine(metric, latest)}'),
        if (trend != null) Text('${l10n.vitalsTrendLabel}: ${_trendLabel(l10n, trend)}'),
        const SizedBox(height: 12),
        if (perDay.isEmpty)
          Text(l10n.noVitalsTrendDataMessage)
        else
          SizedBox(height: 140, child: _buildVitalsChart(perDay)),
        if (metric == 'blood_pressure') ...[
          const SizedBox(height: 4),
          Text(l10n.bloodPressureChartSystolicOnlyNote, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }

  Widget _buildVitalsChart(List<Map<String, dynamic>> perDay) {
    final primary = Theme.of(context).colorScheme.primary;
    return LineChart(
      LineChartData(
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < perDay.length; i++) FlSpot(i.toDouble(), (perDay[i]['value'] as num? ?? 0).toDouble()),
            ],
            isCurved: false,
            color: primary,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  /// Same "blood_pressure needs a second number" branch as
  /// `vitals_screen.dart`'s `_valueLine`, adapted for an analytics
  /// min/max/average/latest point (which carries `value`/`diastolic`/
  /// `unit` directly, not wrapped with its own `metric_type` — this
  /// screen already knows which metric it's looking at from the outer
  /// map key).
  String _pointValueLine(String metric, Map<String, dynamic> point) {
    final value = point['value'];
    if (metric == 'blood_pressure') return '$value/${point['diastolic']} ${point['unit'] ?? 'mmHg'}';
    return '$value ${point['unit'] ?? ''}'.trim();
  }

  String _trendLabel(AppLocalizations l10n, String trend) {
    switch (trend) {
      case 'rising':
        return l10n.vitalsTrendRising;
      case 'falling':
        return l10n.vitalsTrendFalling;
      default:
        return l10n.vitalsTrendSteady;
    }
  }

  String _formatPercent(double value) => '${(value * 100).round()}%';
}
