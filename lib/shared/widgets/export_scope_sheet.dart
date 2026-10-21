import 'dart:typed_data';

import 'package:dio/dio.dart' show ResponseType;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/providers.dart';
import '../../core/sharing/share_source.dart';

/// Tasks 5.6/5.7 — the "export" action both `records_contract.md` and
/// `vitals_contract.md` describe identically: `GET .../export?scope=
/// complete|year|month(&year&month)` returns a PDF, chosen via a
/// 3-option sheet (mockup 15c "all / this year / this month" — the
/// same choice `vitals_contract.md` reuses for its own PDF).
/// Factored out once here instead of being built twice, one for
/// `medical_vault_screen.dart` and one for `vitals_screen.dart`.
///
/// The downloaded PDF is handed to the OS share sheet (`ShareSource`)
/// rather than opened in an in-app viewer — see
/// `medical_vault_screen.dart`'s doc comment for why no viewer was
/// built this batch. Same bytes-via-`ResponseType.bytes` pattern Task
/// 4.8 already established for downloading a voice message's audio.
Future<void> showExportScopeSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String exportPath,
  required String fileNamePrefix,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final choice = await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _ExportScopeForm(),
  );
  if (choice == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(SnackBar(content: Text(l10n.preparingExportMessage), duration: const Duration(seconds: 30)));
  try {
    final response = await ref
        .read(apiClientProvider)
        .get<List<int>>(exportPath, queryParameters: choice, responseType: ResponseType.bytes);
    final bytes = Uint8List.fromList(response.data ?? []);
    messenger.hideCurrentSnackBar();
    if (bytes.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.exportFailedMessage)));
      return;
    }
    final scopeSuffix = choice['scope'] == 'year'
        ? '_${choice['year']}'
        : (choice['scope'] == 'month' ? '_${choice['year']}-${(choice['month'] as int).toString().padLeft(2, '0')}' : '');
    await ref.read(shareSourceProvider).shareBytes(bytes: bytes, fileName: '$fileNamePrefix$scopeSuffix.pdf');
  } on ApiException catch (e) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(e.code == 'MODULE_ACCESS_DENIED' ? l10n.healthRecordsAccessDeniedMessage : l10n.exportFailedMessage)));
  }
}

class _ExportScopeForm extends StatefulWidget {
  const _ExportScopeForm();

  @override
  State<_ExportScopeForm> createState() => _ExportScopeFormState();
}

class _ExportScopeFormState extends State<_ExportScopeForm> {
  String _scope = 'complete';
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final years = List.generate(6, (i) => DateTime.now().year - i);
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.exportSheetTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.exportScopeCompleteLabel),
            value: 'complete',
            groupValue: _scope,
            onChanged: (value) => setState(() => _scope = value!),
          ),
          RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.exportScopeYearLabel),
            value: 'year',
            groupValue: _scope,
            onChanged: (value) => setState(() => _scope = value!),
          ),
          if (_scope == 'year')
            Padding(
              padding: const EdgeInsets.only(left: 32, bottom: 8),
              child: DropdownButton<int>(
                value: _year,
                items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                onChanged: (value) => setState(() => _year = value!),
              ),
            ),
          RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.exportScopeMonthLabel),
            value: 'month',
            groupValue: _scope,
            onChanged: (value) => setState(() => _scope = value!),
          ),
          if (_scope == 'month')
            Padding(
              padding: const EdgeInsets.only(left: 32, bottom: 8),
              child: Row(
                children: [
                  DropdownButton<int>(
                    value: _year,
                    items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                    onChanged: (value) => setState(() => _year = value!),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: _month,
                    items: List.generate(12, (i) => i + 1)
                        .map((m) => DropdownMenuItem(value: m, child: Text('$m')))
                        .toList(),
                    onChanged: (value) => setState(() => _month = value!),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancelButton))),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop({
                    'scope': _scope,
                    if (_scope == 'year' || _scope == 'month') 'year': _year,
                    if (_scope == 'month') 'month': _month,
                  }),
                  child: Text(l10n.exportButtonLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
