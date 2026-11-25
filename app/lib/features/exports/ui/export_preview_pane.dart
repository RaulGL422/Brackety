import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/export_models.dart';
import '../state/export_controller.dart';

/// The file as it will come out: its first rows, updated a moment after each change.
class ExportPreviewPane extends ConsumerWidget {
  const ExportPreviewPane({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final draft = ref.watch(exportDraftProvider(eventId));
    final preview = ref.watch(exportPreviewProvider(eventId));
    final shown = preview.value;
    if (draft == null || draft.columns.isEmpty) {
      return Center(child: Text(l10n.exportNoColumns));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.m,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Semantics(
              header: true,
              child: Text(l10n.exportStepPreview, style: text.titleMedium),
            ),
            if (shown != null)
              Text(
                l10n.exportRowsShown(shown.rows.length, shown.totalRows),
                style: text.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        SizedBox(
          height: AppSpacing.xs,
          child: preview.isLoading ? const LinearProgressIndicator() : null,
        ),
        if (preview.hasError && !preview.isLoading)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(child: Text(l10n.exportPreviewError)),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.s),
        Expanded(
          child: switch (shown) {
            null => const SizedBox.shrink(),
            ExportPreview(rows: []) => Text(l10n.exportPreviewEmpty),
            _ => _PreviewTable(preview: shown),
          },
        ),
      ],
    );
  }
}

/// Wide tables scroll on their own, never the page (docs/07-diseno.md).
class _PreviewTable extends StatelessWidget {
  const _PreviewTable({required this.preview});

  final ExportPreview preview;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget cell(String? value) => ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AppSizes.compactTableColumnWidth,
      ),
      child: Text(value ?? ''),
    );
    return Scrollbar(
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(colors.surfaceContainerLow),
            columnSpacing: AppSpacing.xl,
            columns: [
              for (final h in preview.headers)
                DataColumn(
                  label: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSizes.compactTableColumnWidth,
                    ),
                    child: Text(h),
                  ),
                ),
            ],
            rows: [
              for (final row in preview.rows)
                DataRow(
                  cells: [for (final value in row) DataCell(cell(value))],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
