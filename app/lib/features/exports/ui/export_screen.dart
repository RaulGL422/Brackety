import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/async_view.dart';
import '../../../core/download/file_download.dart';
import '../../../core/up_button.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/export_models.dart';
import '../data/export_repository.dart';
import '../state/export_controller.dart';
import 'export_columns.dart';
import 'export_preview_pane.dart';
import 'export_rows.dart';
import 'export_sections.dart';

/// Custom exports (docs/producto/exportaciones.md): the club builds the file and sees it as it goes. Wide, the
/// settings on the left and the preview on the right; narrow, one step at a time.
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  static const _stepCount = 5;

  var _step = 0;
  var _busy = false;

  ({String eventId, String language}) get _sheetsKey => (
    eventId: widget.eventId,
    language: Localizations.localeOf(context).languageCode == 'en'
        ? 'en'
        : 'es',
  );

  Future<void> _download(ExportSheet sheet, ExportDraft draft) async {
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    final personal = [
      for (final key in draft.columns)
        if (sheet.field(key)!.isPersonal)
          draft.titles[key] ?? sheet.field(key)!.title,
    ];
    if (personal.isNotEmpty && !await _confirmPersonal(personal)) return;
    setState(() => _busy = true);
    try {
      final file = await ref
          .read(exportRepositoryProvider)
          .download(widget.eventId, draft);
      await ref.read(saveFileProvider)(file.name, file.bytes, file.mimeType);
    } on DioException {
      toasts.show(l10n.exportError, kind: ToastKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmPersonal(List<String> columns) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        icon: const Icon(Icons.shield_outlined),
        title: Text(l10n.exportPersonalTitle),
        content: Text(l10n.exportPersonalBody(columns.join(', '))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.exportDownload),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final key = _sheetsKey;
    return Scaffold(
      appBar: AppBar(
        leading: UpButton(
          label: l10n.eventClubPanel,
          fallback: '/events/${widget.eventId}/club',
        ),
        leadingWidth: UpButton.leadingWidth(context),
        title: Text(l10n.exportCustom),
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(AppSpacing.xs),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: AsyncView(
        value: ref.watch(exportSheetsProvider(key)),
        onRetry: () => ref.invalidate(exportSheetsProvider(key)),
        data: (sheets) {
          final draft = ref.watch(exportDraftProvider(widget.eventId));
          if (draft == null) {
            // The first sheet to start with, once they arrive.
            if (sheets.isNotEmpty) {
              Future.microtask(
                () => ref
                    .read(exportDraftProvider(widget.eventId).notifier)
                    .pickSheet(sheets.first),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }
          final sheet = sheets.firstWhere((s) => s.key == draft.sheet);
          return WindowSize.of(context) == WindowSize.expanded
              ? _wide(sheets, sheet, draft)
              : _steps(sheets, sheet, draft);
        },
      ),
    );
  }

  Widget _settings(
    List<ExportSheet> sheets,
    ExportSheet sheet,
    ExportDraft draft,
    int step,
  ) {
    final edit = ExportEdit(
      eventId: widget.eventId,
      sheet: sheet,
      draft: draft,
    );
    return switch (step) {
      0 => SheetChoice(eventId: widget.eventId, sheets: sheets, draft: draft),
      1 => ColumnsEditor(edit),
      2 => RowsEditor(edit),
      _ => FileOptions(edit),
    };
  }

  Widget _downloadButton(ExportSheet sheet, ExportDraft draft) {
    final l10n = AppLocalizations.of(context);
    return FilledButton.icon(
      onPressed: _busy || draft.columns.isEmpty
          ? null
          : () => _download(sheet, draft),
      icon: const Icon(Icons.download),
      label: Text(l10n.exportDownload),
    );
  }

  Widget _wide(List<ExportSheet> sheets, ExportSheet sheet, ExportDraft draft) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: AppSizes.formMaxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  children: [
                    for (var step = 0; step < _stepCount - 1; step++)
                      _settings(sheets, sheet, draft, step),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: _downloadButton(sheet, draft),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ExportPreviewPane(eventId: widget.eventId),
          ),
        ),
      ],
    );
  }

  Widget _steps(
    List<ExportSheet> sheets,
    ExportSheet sheet,
    ExportDraft draft,
  ) {
    final l10n = AppLocalizations.of(context);
    final last = _step == _stepCount - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            AppSpacing.l,
            AppSpacing.l,
            0,
          ),
          child: Text(
            l10n.exportStepOf(_step + 1, _stepCount),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: last
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: ExportPreviewPane(eventId: widget.eventId),
                )
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  children: [_settings(sheets, sheet, draft, _step)],
                ),
        ),
        const Divider(height: 1),
        _stepButtons(sheet, draft, last),
      ],
    );
  }

  Widget _stepButtons(ExportSheet sheet, ExportDraft draft, bool last) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        // With large text the buttons stack instead of overflowing.
        child: OverflowBar(
          alignment: _step > 0
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.end,
          overflowAlignment: OverflowBarAlignment.end,
          overflowSpacing: AppSpacing.s,
          spacing: AppSpacing.s,
          children: [
            if (_step > 0)
              TextButton.icon(
                onPressed: () => setState(() => _step--),
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.exportBack),
              ),
            if (last)
              _downloadButton(sheet, draft)
            else
              FilledButton.icon(
                onPressed: () => setState(() => _step++),
                icon: const Icon(Icons.arrow_forward),
                label: Text(l10n.exportNext),
              ),
          ],
        ),
      ),
    );
  }
}
