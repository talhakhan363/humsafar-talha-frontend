import 'package:dio/dio.dart' show FormData, MultipartFile;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humsafar_frontend/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/files/file_providers.dart';
import '../../../core/files/file_picker_source.dart';
import '../../../core/formatting/format_helpers.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../../core/theme/humsafar_colors.dart';
import '../../../shared/widgets/accessibility_toggle_button.dart';
import '../../../shared/widgets/language_switch_button.dart';
import 'medical_vault_screen.dart' show categoryLabel;

const _kMaxFileBytes = 10 * 1024 * 1024; // 10 MB, matches records_contract.md's own limit.
const _kAllowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

/// Task 5.6 — mockup 15b "Add record". Also serves as the edit form
/// (PATCH, per `records_contract.md`): pass [existing] and the file
/// picker section disappears entirely, since the contract is explicit
/// the file itself cannot be replaced ("delete and add again").
///
/// `client_id` is generated once per screen instance (not per
/// keystroke/tap), same pattern as `voice_recorder_sheet.dart`'s
/// `_clientId` — one random id for the whole add attempt, reused if
/// the person retries after a network failure, per the contract's safe
/// retry rule.
class AddRecordScreen extends ConsumerStatefulWidget {
  const AddRecordScreen({super.key, required this.dependentId, this.existing});

  final String dependentId;
  final Map<String, dynamic>? existing;

  @override
  ConsumerState<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends ConsumerState<AddRecordScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  String _category = 'prescription';
  DateTime _recordDate = DateTime.now();
  PickedFileData? _pickedFile;
  bool _isSaving = false;
  String? _error;
  // Bug fix (2026-10-30, Sarim's G-01): this was a hand-rolled
  // timestamp+random string, not a real UUID, so the backend's safe-retry
  // check 422'd every new record.
  final String _clientId = const Uuid().v4();
  // (P-06 fix) same plugin dependent_kyc_screen.dart already uses for
  // liveness capture — no new, unvetted plugin needed.
  final _imagePicker = ImagePicker();
  bool _isCapturingPhoto = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?['title'] as String? ?? '');
    _notesController = TextEditingController(text: existing?['notes'] as String? ?? '');
    _category = existing?['category'] as String? ?? 'prescription';
    final existingDate = DateTime.tryParse(existing?['record_date'] as String? ?? '');
    if (existingDate != null) _recordDate = existingDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _recordDate = picked);
  }

  Future<void> _pickFile() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await ref.read(filePickerSourceProvider).pickFile(allowedExtensions: _kAllowedExtensions);
    if (picked == null) return;
    if (picked.sizeBytes > _kMaxFileBytes) {
      setState(() => _error = l10n.fileTooLargeMessage);
      return;
    }
    setState(() {
      _pickedFile = picked;
      _error = null;
    });
  }

  // Bug fix (P-06, QA 5.10 Results v1.0, R-02): "gallery or files" was
  // the only way in — no camera option, even though the main use case
  // (per the finding) is a Dependent photographing a prescription on
  // the spot, not picking an existing photo. `image_picker`'s camera
  // source hands back the same bytes shape `_pickFile` already uses,
  // so this reuses `_pickedFile`/`FormData` unchanged below; only the
  // source of the bytes differs.
  Future<void> _takePhoto() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isCapturingPhoto = true);
    try {
      final photo = await _imagePicker.pickImage(source: ImageSource.camera, maxWidth: 2000, imageQuality: 85);
      if (photo == null) return; // cancelled
      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      if (bytes.length > _kMaxFileBytes) {
        setState(() => _error = l10n.fileTooLargeMessage);
        return;
      }
      setState(() {
        _pickedFile = PickedFileData(bytes: bytes, fileName: 'record_photo_${_clientId.substring(0, 8)}.jpg', sizeBytes: bytes.length);
        _error = null;
      });
    } finally {
      if (mounted) setState(() => _isCapturingPhoto = false);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final title = _titleController.text.trim();
    final notes = _notesController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = l10n.fieldRequiredError);
      return;
    }
    if (!_isEdit && _pickedFile == null && notes.isEmpty) {
      setState(() => _error = l10n.recordNeedsContentError);
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      if (_isEdit) {
        final recordId = widget.existing!['record_id'] as String;
        await ref.read(apiClientProvider).patch(
              '/dependents/${widget.dependentId}/records/$recordId',
              data: {
                'title': title,
                'category': _category,
                'record_date': formatDateYmd(_recordDate),
                'notes': notes,
              },
            );
      } else {
        final formData = FormData.fromMap({
          'category': _category,
          'title': title,
          'record_date': formatDateYmd(_recordDate),
          'notes': notes,
          'client_id': _clientId,
          if (_pickedFile != null)
            'file': MultipartFile.fromBytes(_pickedFile!.bytes, filename: _pickedFile!.fileName),
        });
        await ref.read(apiClientProvider).post('/dependents/${widget.dependentId}/records', data: formData);
      }
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
      case 'RECORD_NEEDS_CONTENT':
        return l10n.recordNeedsContentError;
      case 'FILE_TOO_LARGE':
        return l10n.fileTooLargeMessage;
      case 'UNSUPPORTED_FILE':
        return l10n.unsupportedFileMessage;
      case 'RECORDS_LIMIT':
        return l10n.recordsLimitMessage;
      case 'CATEGORY_NOT_ALLOWED':
        return l10n.categoryNotAllowedMessage;
      case 'MODULE_ACCESS_DENIED':
        return l10n.healthRecordsAccessDeniedMessage;
      case 'RECORD_MODIFY_DENIED':
        return l10n.recordModifyDeniedMessage;
      case 'INVALID_DATE':
      case 'VALIDATION_ERROR':
        return l10n.recordValidationErrorMessage;
      default:
        return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.editRecordTitle : l10n.addRecordTitle),
        actions: const [LanguageSwitchButton(), AccessibilityToggleButton()],
      ),
      // Bug fix (2026-10-30): bottom-nav-bar overlap, see vitals_screen.dart.
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
        children: [
          Text(l10n.recordCategoryFieldLabel, style: Theme.of(context).textTheme.bodyMedium),
          Wrap(
            spacing: 8,
            children: ['prescription', 'lab_report', 'xray', 'other'].map((category) {
              return ChoiceChip(
                label: Text(categoryLabel(l10n, category)),
                selected: _category == category,
                onSelected: (_) => setState(() => _category = category),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(controller: _titleController, decoration: InputDecoration(labelText: l10n.recordTitleFieldLabel)),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.recordDateFieldLabel),
            trailing: Text(formatDateDisplay(_recordDate, languageCode)),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(labelText: l10n.recordNotesFieldLabel),
            maxLines: 4,
          ),
          if (!_isEdit) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: Text(l10n.attachFileButtonLabel),
                  ),
                ),
                const SizedBox(width: 12),
                // (P-06 fix) see _takePhoto's doc comment.
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isCapturingPhoto ? null : _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(l10n.takePhotoButtonLabel),
                  ),
                ),
              ],
            ),
            if (_pickedFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_pickedFile!.fileName, style: Theme.of(context).textTheme.bodyMedium),
              ),
            if (_pickedFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(formatFileSize(_pickedFile!.sizeBytes), style: Theme.of(context).textTheme.bodySmall),
              ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l10n.fileCannotBeReplacedNote, style: Theme.of(context).textTheme.bodySmall),
            ),
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
}
