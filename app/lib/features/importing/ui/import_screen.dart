import 'dart:convert';

import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/download/file_download.dart';
import '../../../core/upload/file_upload.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../club/state/club_providers.dart';
import '../../legal/ui/legal_links.dart';
import '../data/import_models.dart';
import '../data/import_repository.dart';
import 'issue_text.dart';
import 'row_dialog.dart';
import '../../../core/up_button.dart';

const _maxFiles = 10;

/// Bulk import (docs/modulos/importacion-alumnos.md): upload a list, review it, register it.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  final _text = TextEditingController();
  var _files = <PickedFile>[];
  var _consent = false;
  var _busy = false;

  /// Null while uploading; the list under review afterwards.
  List<CheckedRow>? _rows;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  ImportRepository get _repository => ref.read(importRepositoryProvider);

  Future<void> _pick({required bool photos}) async {
    final picked = await ref.read(pickFilesProvider)(
      accept: photos ? 'image/jpeg,image/png,image/webp' : '.csv,.txt,.xlsx',
      multiple: photos,
    );
    if (picked.isEmpty) return;
    setState(() => _files = [..._files, ...picked].take(_maxFiles).toList());
  }

  Future<void> _downloadTemplate() async {
    const template =
        '﻿nombre;apellidos;fecha_nacimiento;estatura_cm;categoria\r\n'
        'Lucía;García López;12/03/2016;128;\r\n';
    await ref.read(saveFileProvider)(
      'plantilla_alumnos.csv',
      utf8.encode(template),
      'text/csv',
    );
  }

  Future<void> _read() async {
    await _run(() async {
      final rows = await _repository.read(
        widget.eventId,
        files: _files,
        text: _text.text,
      );
      setState(() => _rows = rows);
    });
  }

  /// Sends the edited rows to be checked again.
  Future<void> _change(List<ImportRow> rows) async {
    await _run(() async {
      final checked = rows.isEmpty
          ? <CheckedRow>[]
          : await _repository.check(widget.eventId, rows);
      setState(() => _rows = checked);
    });
  }

  Future<void> _register() async {
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    final navigator = Navigator.of(context);
    await _run(() async {
      final result = await _repository.register(widget.eventId, [
        for (final r in _rows!) r.row,
      ]);
      if (result.registered == 0) {
        setState(() => _rows = result.rows);
        toasts.show(l10n.importRegisterRefused, kind: ToastKind.error);
        return;
      }
      ref.invalidate(participantsProvider(widget.eventId));
      toasts.show(l10n.importRegistered(result.registered));
      navigator.pop();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    setState(() => _busy = true);
    try {
      await action();
    } on DioException catch (e) {
      toasts.show(switch (e.response?.statusCode) {
        400 => l10n.importInvalidFiles(_maxFiles),
        429 => l10n.importTooMany,
        _ => l10n.importReadError,
      }, kind: ToastKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = _rows;
    return Scaffold(
      appBar: AppBar(
        leading: UpButton(
          label: l10n.clubParticipants,
          fallback: '/events/${widget.eventId}/club',
        ),
        leadingWidth: UpButton.leadingWidth(context),
        title: Text(l10n.importButton),
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: rows == null ? _upload(context) : _review(context, rows),
        ),
      ),
    );
  }

  Widget _upload(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final hasList = _files.isNotEmpty || _text.text.trim().isNotEmpty;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.l),
      children: [
        Text(l10n.importFormatTitle, style: text.titleMedium),
        const SizedBox(height: AppSpacing.s),
        Text(l10n.importFormatBody),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.download_outlined),
            label: Text(l10n.importTemplate),
            onPressed: _downloadTemplate,
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        Wrap(
          spacing: AppSpacing.m,
          runSpacing: AppSpacing.s,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(l10n.importPickPhotos),
              onPressed: _busy || _files.length >= _maxFiles
                  ? null
                  : () => _pick(photos: true),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(l10n.importPickFile),
              onPressed: _busy || _files.length >= _maxFiles
                  ? null
                  : () => _pick(photos: false),
            ),
          ],
        ),
        for (final (i, f) in _files.indexed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: Text(f.name),
            trailing: IconButton(
              tooltip: l10n.importRemoveRow,
              icon: const Icon(Icons.close),
              onPressed: _busy
                  ? null
                  : () => setState(() => _files = [..._files]..removeAt(i)),
            ),
          ),
        const SizedBox(height: AppSpacing.m),
        TextField(
          controller: _text,
          enabled: !_busy,
          minLines: 3,
          maxLines: 8,
          decoration: InputDecoration(labelText: l10n.importPasteHint),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.m),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _consent,
          onChanged: _busy ? null : (v) => setState(() => _consent = v!),
          title: Text(l10n.importConsent, style: text.bodySmall),
        ),
        PrivacyNotice(message: l10n.importPrivacyNotice),
        const SizedBox(height: AppSpacing.m),
        if (_busy) ...[
          Text(l10n.importReading, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.s),
        ],
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSizes.touchTarget),
          ),
          icon: const Icon(Icons.document_scanner_outlined),
          label: Text(l10n.importRead),
          onPressed: hasList && _consent && !_busy ? _read : null,
        ),
      ],
    );
  }

  Widget _review(BuildContext context, List<CheckedRow> rows) {
    final l10n = AppLocalizations.of(context);
    final errors = rows.where((r) => !r.isValid).length;
    final warnings = rows.where((r) => r.warnings.isNotEmpty).length;
    final edit = [for (final r in rows) r.row];
    return Column(
      children: [
        Expanded(
          child: rows.isEmpty
              ? Center(child: Text(l10n.importEmpty))
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  itemCount: rows.length,
                  itemBuilder: (context, i) => _RowCard(
                    number: i + 1,
                    row: rows[i],
                    enabled: !_busy,
                    onEdit: () async {
                      final edited = await showRowDialog(
                        context,
                        row: rows[i].row,
                      );
                      if (edited != null) _change([...edit]..[i] = edited);
                    },
                    onRemove: () => _change([...edit]..removeAt(i)),
                    onCategory: (id) =>
                        _change([...edit]..[i] = edit[i].withCategory(id)),
                  ),
                ),
        ),
        Material(
          elevation: 3,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.importSummary(rows.length, errors, warnings)),
                  const SizedBox(height: AppSpacing.s),
                  Wrap(
                    spacing: AppSpacing.m,
                    runSpacing: AppSpacing.s,
                    alignment: WrapAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() => _rows = null),
                        child: Text(l10n.importStartOver),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.person_add_alt),
                        label: Text(l10n.importAddRow),
                        onPressed: _busy
                            ? null
                            : () async {
                                final added = await showRowDialog(context);
                                if (added != null) _change([...edit, added]);
                              },
                      ),
                      FilledButton(
                        onPressed: rows.isNotEmpty && errors == 0 && !_busy
                            ? _register
                            : null,
                        child: Text(l10n.importRegister(rows.length)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RowCard extends StatelessWidget {
  const _RowCard({
    required this.number,
    required this.row,
    required this.enabled,
    required this.onEdit,
    required this.onRemove,
    required this.onCategory,
  });

  final int number;
  final CheckedRow row;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  /// The club settles the category: an id, or null to go by age.
  final ValueChanged<String?> onCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final colors = BracketyColors.of(context);
    final text = Theme.of(context).textTheme;
    final r = row.row;
    final locale = Localizations.localeOf(context).toLanguageTag();
    // While the category is still to be settled, only the age: "no category" would mislead.
    final categoryPending = row.errors.any((e) => e.field == 'category');
    final details = [
      if (r.birthDate != null) DateFormat.yMd(locale).format(r.birthDate!),
      if (r.heightCm != null) l10n.heightCm(r.heightCm!),
      if (row.age != null)
        categoryPending
            ? '${row.age} ${l10n.categoryAgeSuffix}'
            : l10n.participantAgeCategory(
                row.age!,
                row.categoryName ?? l10n.noCategory,
              ),
    ].join(' · ');
    final (icon, color) = !row.isValid
        ? (Icons.error_outline, scheme.error)
        : row.warnings.isNotEmpty
        ? (Icons.help_outline, colors.warning)
        : (Icons.check_circle_outline, colors.success);
    final mismatch = row.errors.any(
      (e) =>
          e.code == IssueCode.categoryMismatch ||
          e.code == IssueCode.unknownCategory,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$number. ${r.fullName.isEmpty ? '—' : r.fullName}',
                        style: text.titleMedium,
                      ),
                      if (details.isNotEmpty)
                        Text(details, style: text.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.importEditRow,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: enabled ? onEdit : null,
                ),
                IconButton(
                  tooltip: l10n.importRemoveRow,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: enabled ? onRemove : null,
                ),
              ],
            ),
            for (final e in row.errors)
              Text(
                issueText(l10n, e, row),
                style: text.bodyMedium?.copyWith(color: scheme.error),
              ),
            for (final w in row.warnings)
              Text(
                issueText(l10n, w, row),
                style: text.bodyMedium?.copyWith(color: colors.warning),
              ),
            if (mismatch)
              Wrap(
                spacing: AppSpacing.s,
                children: [
                  if (row.indicatedCategoryId != null)
                    OutlinedButton(
                      onPressed: enabled
                          ? () => onCategory(row.indicatedCategoryId)
                          : null,
                      child: Text(
                        l10n.importUseCategory(row.indicatedCategoryName!),
                      ),
                    ),
                  if (row.ageCategoryName != null)
                    OutlinedButton(
                      onPressed: enabled ? () => onCategory(null) : null,
                      child: Text(l10n.importUseCategory(row.ageCategoryName!)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
