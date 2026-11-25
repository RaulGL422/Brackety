import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/export_models.dart';
import '../state/export_controller.dart';

/// A section of the export's settings: its title, a line saying what it does and its controls.
class ExportSection extends StatelessWidget {
  const ExportSection({
    super.key,
    required this.title,
    this.help,
    required this.children,
  });

  final String title;
  final String? help;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(title, style: text.titleMedium)),
          if (help != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              help!,
              style: text.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s),
          ...children,
        ],
      ),
    );
  }
}

/// What every part of the settings works on: the event, its chosen sheet and the draft.
class ExportEdit {
  const ExportEdit({
    required this.eventId,
    required this.sheet,
    required this.draft,
  });

  final String eventId;
  final ExportSheet sheet;
  final ExportDraft draft;
}

/// Which data: one of the event's sheets.
class SheetChoice extends ConsumerWidget {
  const SheetChoice({
    super.key,
    required this.eventId,
    required this.sheets,
    required this.draft,
  });

  final String eventId;
  final List<ExportSheet> sheets;
  final ExportDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ExportSection(
      title: l10n.exportStepData,
      help: l10n.exportSheetHelp,
      children: [
        // All in sight and short, so the columns (what changes most) stay near the top.
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            for (final sheet in sheets)
              ChoiceChip(
                label: Text(sheet.title),
                selected: sheet.key == draft.sheet,
                onSelected: (_) => ref
                    .read(exportDraftProvider(eventId).notifier)
                    .pickSheet(sheet),
              ),
          ],
        ),
      ],
    );
  }
}

/// How the file comes out: split or not, format, header language and, for a PDF, its title and page.
class FileOptions extends ConsumerWidget {
  const FileOptions(this.edit, {super.key});

  final ExportEdit edit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(exportDraftProvider(edit.eventId).notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _format(context, controller),
        _split(context, controller),
        _headers(context, controller),
        if (edit.draft.format == ExportFormat.pdf) ..._pdf(context, controller),
      ],
    );
  }

  Widget _format(BuildContext context, ExportDraftController controller) {
    final l10n = AppLocalizations.of(context);
    return ExportSection(
      title: l10n.exportFormat,
      children: [
        SegmentedButton<ExportFormat>(
          segments: const [
            ButtonSegment(value: ExportFormat.csv, label: Text('CSV')),
            ButtonSegment(value: ExportFormat.xlsx, label: Text('Excel')),
            ButtonSegment(value: ExportFormat.pdf, label: Text('PDF')),
          ],
          selected: {edit.draft.format},
          onSelectionChanged: (s) => controller.format(s.single),
        ),
      ],
    );
  }

  Widget _split(BuildContext context, ExportDraftController controller) {
    final l10n = AppLocalizations.of(context);
    return ExportSection(
      title: l10n.exportSplit,
      help: edit.draft.splitBy == null
          ? null
          : switch (edit.draft.format) {
              ExportFormat.csv => l10n.exportSplitCsv,
              ExportFormat.xlsx => l10n.exportSplitExcel,
              ExportFormat.pdf => l10n.exportSplitPdf,
            },
      children: [
        DropdownButtonFormField<String?>(
          initialValue: edit.draft.splitBy,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.exportSplit),
          items: [
            DropdownMenuItem(child: Text(l10n.exportNoSplit)),
            for (final f in edit.sheet.fields)
              DropdownMenuItem(value: f.key, child: Text(f.title)),
          ],
          onChanged: controller.splitBy,
        ),
      ],
    );
  }

  Widget _headers(BuildContext context, ExportDraftController controller) {
    final l10n = AppLocalizations.of(context);
    return ExportSection(
      title: l10n.exportHeaders,
      children: [
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(l10n.exportSpanish)),
            ButtonSegment(value: true, label: Text(l10n.exportEnglish)),
          ],
          selected: {edit.draft.english},
          onSelectionChanged: (s) => controller.english(s.single),
        ),
      ],
    );
  }

  List<Widget> _pdf(BuildContext context, ExportDraftController controller) {
    final l10n = AppLocalizations.of(context);
    return [
      ExportSection(
        title: l10n.exportPdfTitle,
        children: [
          TextFormField(
            initialValue: edit.draft.pdfTitle,
            maxLength: 120,
            decoration: InputDecoration(
              labelText: l10n.exportPdfTitle,
              helperText: l10n.exportPdfTitleHelp,
            ),
            onChanged: controller.pdfTitle,
          ),
        ],
      ),
      ExportSection(
        title: l10n.exportOrientation,
        children: [
          SegmentedButton<bool?>(
            segments: [
              ButtonSegment(value: null, label: Text(l10n.exportAutomatic)),
              ButtonSegment(value: false, label: Text(l10n.exportPortrait)),
              ButtonSegment(value: true, label: Text(l10n.exportLandscape)),
            ],
            selected: {edit.draft.landscape},
            onSelectionChanged: (s) => controller.landscape(s.single),
          ),
        ],
      ),
    ];
  }
}

/// "Add …": picks one of [fields] in a dialog and hands its key over; off when there is none left.
class ExportAddButton extends StatelessWidget {
  const ExportAddButton({
    super.key,
    required this.icon,
    required this.label,
    required this.fields,
    required this.onPicked,
  });

  final IconData icon;
  final String label;
  final List<ExportField> fields;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: OutlinedButton.icon(
        onPressed: fields.isEmpty
            ? null
            : () async {
                final key = await chooseField(context, fields);
                if (key != null) onPicked(key);
              },
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

/// One of [fields], picked in a dialog; null if closed.
Future<String?> chooseField(BuildContext context, List<ExportField> fields) {
  final l10n = AppLocalizations.of(context);
  return showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l10n.exportChooseColumn),
      children: [
        for (final f in fields)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, f.key),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizes.touchTarget,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(f.title),
              ),
            ),
          ),
      ],
    ),
  );
}
