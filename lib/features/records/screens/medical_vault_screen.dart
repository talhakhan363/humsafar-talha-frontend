import 'dart:typed_data';

import 'package:dio/dio.dart' show ResponseType;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';

import '../../../core/formatting/format_helpers.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/sharing/share_source.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/export_scope_sheet.dart';
import '../../../shared/widgets/language_switch_button.dart';
import 'add_record_screen.dart';

const _categories = ['prescription', 'lab_report', 'xray', 'other'];

String categoryLabel(AppLocalizations l10n, String category) {
  switch (category) {
    case 'prescription':
      return l10n.recordCategoryPrescription;
    case 'lab_report':
      return l10n.recordCategoryLabReport;
    case 'xray':
      return l10n.recordCategoryXray;
    case 'other':
      return l10n.recordCategoryOther;
    default:
      return category;
  }
}

/// Task 5.6 — mockup 15 "Medical Vault", grounded in
/// `records_contract.md`. List of a Dependent's medical records, with
/// a category filter (re-queries the server per the contract's own
/// `category` query param, rather than filtering a client-side cache —
/// consistent with every other list screen's `include_inactive`-style
/// filter), add (`AddRecordScreen`), edit (same screen, file picker
/// hidden — the contract is explicit the file itself cannot be
/// replaced), and delete, each gated by the record's own `can_modify`.
///
/// **Named scope cut (flagged, not silent):** no in-app PDF/photo
/// viewer. Tapping a record's file icon downloads it
/// (`GET .../records/{id}/file`, same `ResponseType.bytes` pattern
/// Task 4.8 used for voice-message audio) and hands it straight to the
/// OS share sheet (`ShareSource`) instead of rendering it in-app. The
/// task is literally titled "list, upload, export" — viewing was never
/// asked for — and this is already the largest batch yet; adding a
/// PDF-rendering dependency on top of `file_picker`/`share_plus` would
/// have meant a third new, unvetted plugin in one delivery. Downloading
/// and sharing still gets the file open in the phone's own viewer app
/// (via whatever the OS share sheet offers), just one tap further than
/// an inline preview would be.
///
/// Export (15c) and Doctor links (15f) are reached from this screen's
/// app bar menu; Record access (15e, Primary-only) also lives there.
/// Appointments (15d) is a sibling screen reached directly from
/// `DependentDetailScreen`, not nested under the Vault, since nothing
/// in the contract ties appointments to a record category filter the
/// way the other three menu items share.
class MedicalVaultScreen extends ConsumerStatefulWidget {
  const MedicalVaultScreen({super.key, required this.dependentId, this.canManageAccess = false});

  final String dependentId;

  /// True only when opened by the Primary Guardian — shows the
  /// "Record access" menu item (mockup 15e, Primary-only per
  /// `records_contract.md`'s `NOT_PRIMARY_GUARDIAN` error). False for
  /// a Secondary Guardian or a Dependent viewing their own vault.
  final bool canManageAccess;

  @override
  ConsumerState<MedicalVaultScreen> createState() => _MedicalVaultScreenState();
}

class _MedicalVaultScreenState extends ConsumerState<MedicalVaultScreen> {
  static const _pageSize = 30;

  List<Map<String, dynamic>> _records = [];
  String? _categoryFilter;
  int _total = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _loadError;
  final Set<String> _pendingDelete = {};
  final Set<String> _pendingDownload = {};

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
            '/dependents/${widget.dependentId}/records',
            queryParameters: {if (_categoryFilter != null) 'category': _categoryFilter, 'limit': _pageSize, 'offset': 0},
          );
      if (!mounted) return;
      setState(() {
        _records = (response.data?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        _total = response.data?['total'] as int? ?? _records.length;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = _messageFor(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    try {
      final response = await ref.read(apiClientProvider).get<Map<String, dynamic>>(
            '/dependents/${widget.dependentId}/records',
            queryParameters: {
              if (_categoryFilter != null) 'category': _categoryFilter,
              'limit': _pageSize,
              'offset': _records.length,
            },
          );
      if (!mounted) return;
      setState(() => _records = [..._records, ...(response.data?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>()]);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_messageFor(e))));
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  String _messageFor(ApiException e) {
    final l10n = AppLocalizations.of(context)!;
    switch (e.code) {
      case 'MODULE_ACCESS_DENIED':
        return l10n.healthRecordsAccessDeniedMessage;
      case 'RECORD_NOT_FOUND':
        return l10n.recordNotFoundMessage;
      default:
        return e.message;
    }
  }

  Future<void> _downloadFile(Map<String, dynamic> record) async {
    final recordId = record['record_id'] as String;
    setState(() => _pendingDownload.add(recordId));
    try {
      final response = await ref.read(apiClientProvider).get<List<int>>(
            '/dependents/${widget.dependentId}/records/$recordId/file',
            responseType: ResponseType.bytes,
          );
      final bytes = Uint8List.fromList(response.data ?? []);
      final fileName = record['file_name'] as String? ?? 'record_$recordId';
      await ref.read(shareSourceProvider).shareBytes(bytes: bytes, fileName: fileName);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_messageFor(e))));
    } finally {
      if (mounted) setState(() => _pendingDownload.remove(recordId));
    }
  }

  Future<void> _delete(Map<String, dynamic> record) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteRecordConfirmTitle),
        content: Text(l10n.deleteRecordConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancelButton)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.deleteButtonLabel)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final recordId = record['record_id'] as String;
    setState(() => _pendingDelete.add(recordId));
    try {
      await ref.read(apiClientProvider).delete('/dependents/${widget.dependentId}/records/$recordId');
      if (!mounted) return;
      setState(() {
        _records.removeWhere((r) => r['record_id'] == recordId);
        _total -= 1;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_messageFor(e))));
    } finally {
      if (mounted) setState(() => _pendingDelete.remove(recordId));
    }
  }

  Future<void> _openAdd() async {
    final added = await context.push<bool>('/records/add', extra: widget.dependentId);
    if (added == true) _load();
  }

  Future<void> _openEdit(Map<String, dynamic> record) async {
    final changed = await context.push<bool>(
      '/records/edit',
      extra: {'dependentId': widget.dependentId, 'record': record},
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.medicalVaultScreenTitle),
        actions: [
          const LanguageSwitchButton(),
          const AccessibilityToggleButton(),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export':
                  showExportScopeSheet(
                    context: context,
                    ref: ref,
                    exportPath: '/dependents/${widget.dependentId}/records/export',
                    fileNamePrefix: 'medical_records',
                  );
                case 'doctor_links':
                  context.push('/records/doctor-links', extra: widget.dependentId);
                case 'record_access':
                  context.push('/records/access', extra: widget.dependentId);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'export', child: Text(l10n.exportRecordsMenuItem)),
              PopupMenuItem(value: 'doctor_links', child: Text(l10n.doctorLinksMenuItem)),
              if (widget.canManageAccess) PopupMenuItem(value: 'record_access', child: Text(l10n.recordAccessMenuItem)),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _openAdd, child: const Icon(Icons.add)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(l10n, null, l10n.recordCategoryAll),
                  for (final category in _categories) _buildFilterChip(l10n, category, categoryLabel(l10n, category)),
                ],
              ),
            ),
          ),
          Expanded(child: RefreshIndicator(onRefresh: _load, child: _buildBody(l10n))),
        ],
      ),
    );
  }

  Widget _buildFilterChip(AppLocalizations l10n, String? category, String label) {
    final selected = _categoryFilter == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _categoryFilter = category);
          _load();
        },
      ),
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
    if (_records.isEmpty) {
      return Center(child: Text(l10n.noRecordsMessage, textAlign: TextAlign.center));
    }
    final languageCode = Localizations.localeOf(context).languageCode;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        ..._records.map((record) {
          final recordId = record['record_id'] as String;
          final hasFile = record['has_file'] as bool? ?? false;
          final canModify = record['can_modify'] as bool? ?? false;
          final recordDate = DateTime.tryParse(record['record_date'] as String? ?? '');
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(hasFile ? Icons.insert_drive_file_outlined : Icons.sticky_note_2_outlined),
              title: Text(record['title'] as String? ?? ''),
              subtitle: Text(
                '${categoryLabel(l10n, record['category'] as String? ?? '')}'
                '${recordDate == null ? '' : ' · ${formatDateDisplay(recordDate, languageCode)}'}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasFile)
                    IconButton(
                      icon: _pendingDownload.contains(recordId)
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.download_outlined),
                      tooltip: l10n.downloadFileTooltip,
                      onPressed: _pendingDownload.contains(recordId) ? null : () => _downloadFile(record),
                    ),
                  if (canModify) ...[
                    IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _openEdit(record)),
                    IconButton(
                      icon: _pendingDelete.contains(recordId)
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.delete_outline),
                      onPressed: _pendingDelete.contains(recordId) ? null : () => _delete(record),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        if (_records.length < _total)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: _isLoadingMore
                  ? const CircularProgressIndicator()
                  : OutlinedButton(onPressed: _loadMore, child: Text(l10n.loadMoreButtonLabel)),
            ),
          ),
      ],
    );
  }
}
