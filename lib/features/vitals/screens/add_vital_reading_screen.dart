import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/theme/humsafar_colors.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';
import 'vitals_screen.dart' show metricLabel;

const _manualMetrics = ['blood_pressure', 'blood_sugar', 'spo2', 'temperature'];

/// Task 5.7 — mockup 26b "Add reading", grounded in
/// `vitals_contract.md`. Only the four manually-typeable metrics are
/// offered — `heart_rate` is band-only and would 422 if sent here, so
/// it's never in this screen's picker at all (not just disabled), per
/// the contract's own wording. Per-metric fields match the contract's
/// "Allowed values" table exactly: blood pressure needs both
/// top/bottom numbers; blood sugar has a unit choice and an optional
/// context; SpO2 is percent only; temperature has a unit choice.
class AddVitalReadingScreen extends ConsumerStatefulWidget {
  const AddVitalReadingScreen({super.key, required this.dependentId});

  final String dependentId;

  @override
  ConsumerState<AddVitalReadingScreen> createState() => _AddVitalReadingScreenState();
}

class _AddVitalReadingScreenState extends ConsumerState<AddVitalReadingScreen> {
  String _metric = 'blood_pressure';
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _valueController = TextEditingController();
  final _noteController = TextEditingController();
  String _sugarUnit = 'mg/dL';
  String? _sugarContext;
  String _tempUnit = 'C';
  bool _isSaving = false;
  String? _error;
  final String _clientId = '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _valueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final body = <String, dynamic>{'metric_type': _metric, 'client_id': _clientId, 'note': _noteController.text.trim()};
    switch (_metric) {
      case 'blood_pressure':
        final top = double.tryParse(_systolicController.text.trim());
        final bottom = double.tryParse(_diastolicController.text.trim());
        if (top == null || bottom == null) {
          setState(() => _error = l10n.fieldRequiredError);
          return;
        }
        body['value'] = top;
        body['diastolic'] = bottom;
      case 'blood_sugar':
        final value = double.tryParse(_valueController.text.trim());
        if (value == null) {
          setState(() => _error = l10n.fieldRequiredError);
          return;
        }
        body['value'] = value;
        body['unit'] = _sugarUnit;
        if (_sugarContext != null) body['context'] = _sugarContext;
      case 'temperature':
        final value = double.tryParse(_valueController.text.trim());
        if (value == null) {
          setState(() => _error = l10n.fieldRequiredError);
          return;
        }
        body['value'] = value;
        body['unit'] = _tempUnit;
      default: // spo2
        final value = double.tryParse(_valueController.text.trim());
        if (value == null) {
          setState(() => _error = l10n.fieldRequiredError);
          return;
        }
        body['value'] = value;
        body['unit'] = '%';
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await ref.read(apiClientProvider).post('/dependents/${widget.dependentId}/vitals', data: body);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = _messageFor(l10n, e);
      });
    }
  }

  String _messageFor(AppLocalizations l10n, ApiException e) {
    switch (e.code) {
      case 'VITAL_OUT_OF_RANGE':
        return l10n.vitalOutOfRangeMessage;
      case 'VITALS_LIMIT':
        return l10n.vitalsLimitMessage;
      case 'MODULE_ACCESS_DENIED':
        return l10n.healthRecordsAccessDeniedMessage;
      case 'VALIDATION_ERROR':
      case 'INVALID_DATE':
        return l10n.recordValidationErrorMessage;
      default:
        return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addVitalReadingTitle),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      // Bug fix (2026-10-30): bottom-nav-bar overlap, see vitals_screen.dart.
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
        children: [
          Wrap(
            spacing: 8,
            children: _manualMetrics.map((metric) {
              return ChoiceChip(
                label: Text(metricLabel(l10n, metric)),
                selected: _metric == metric,
                onSelected: (_) => setState(() => _metric = metric),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          ..._buildMetricFields(l10n),
          const SizedBox(height: 12),
          TextField(controller: _noteController, decoration: InputDecoration(labelText: l10n.vitalNoteFieldLabel)),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: HumsafarColors.warning)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.saveButtonLabel),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMetricFields(AppLocalizations l10n) {
    final numericOnly = [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))];
    switch (_metric) {
      case 'blood_pressure':
        return [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _systolicController,
                  keyboardType: TextInputType.number,
                  inputFormatters: numericOnly,
                  decoration: InputDecoration(labelText: l10n.systolicFieldLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _diastolicController,
                  keyboardType: TextInputType.number,
                  inputFormatters: numericOnly,
                  decoration: InputDecoration(labelText: l10n.diastolicFieldLabel),
                ),
              ),
            ],
          ),
        ];
      case 'blood_sugar':
        return [
          TextField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            inputFormatters: numericOnly,
            decoration: InputDecoration(labelText: l10n.bloodSugarFieldLabel),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sugarUnit,
                  decoration: InputDecoration(labelText: l10n.unitFieldLabel),
                  items: const ['mg/dL', 'mmol/L'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (value) => setState(() => _sugarUnit = value!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _sugarContext,
                  decoration: InputDecoration(labelText: l10n.sugarContextFieldLabel),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.sugarContextNone)),
                    DropdownMenuItem(value: 'fasting', child: Text(l10n.sugarContextFasting)),
                    DropdownMenuItem(value: 'after_meal', child: Text(l10n.sugarContextAfterMeal)),
                    DropdownMenuItem(value: 'random', child: Text(l10n.sugarContextRandom)),
                  ],
                  onChanged: (value) => setState(() => _sugarContext = value),
                ),
              ),
            ],
          ),
        ];
      case 'temperature':
        return [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _valueController,
                  keyboardType: TextInputType.number,
                  inputFormatters: numericOnly,
                  decoration: InputDecoration(labelText: l10n.temperatureFieldLabel),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _tempUnit,
                items: const ['C', 'F'].map((u) => DropdownMenuItem(value: u, child: Text('°$u'))).toList(),
                onChanged: (value) => setState(() => _tempUnit = value!),
              ),
            ],
          ),
        ];
      default: // spo2
        return [
          TextField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            inputFormatters: numericOnly,
            decoration: InputDecoration(labelText: l10n.spo2FieldLabel),
          ),
        ];
    }
  }
}
