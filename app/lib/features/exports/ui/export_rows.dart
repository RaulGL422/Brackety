import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/export_models.dart';
import '../state/export_controller.dart';
import 'export_filter_row.dart';
import 'export_sections.dart';

/// Which rows and in which order.
class RowsEditor extends ConsumerWidget {
  const RowsEditor(this.edit, {super.key});

  final ExportEdit edit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(exportDraftProvider(edit.eventId).notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_filters(context, controller), _sorting(context, controller)],
    );
  }

  Widget _filters(BuildContext context, ExportDraftController controller) {
    final l10n = AppLocalizations.of(context);
    return ExportSection(
      title: l10n.exportFilters,
      help: l10n.exportFiltersHelp,
      children: [
        for (final (index, filter) in edit.draft.filters.indexed)
          ExportFilterRow(
            key: ValueKey('filter-$index-${filter.column}'),
            field: edit.sheet.field(filter.column)!,
            filter: filter,
            onChanged: (f) => controller.setFilter(index, f),
            onRemove: () => controller.removeFilter(index),
          ),
        ExportAddButton(
          icon: Icons.filter_alt_outlined,
          label: l10n.exportAddFilter,
          fields: edit.sheet.fields,
          onPicked: controller.addFilter,
        ),
      ],
    );
  }

  Widget _sorting(BuildContext context, ExportDraftController controller) {
    final l10n = AppLocalizations.of(context);
    final sorted = {for (final s in edit.draft.sort) s.column};
    return ExportSection(
      title: l10n.exportSort,
      help: l10n.exportSortHelp,
      children: [
        for (final (index, sort) in edit.draft.sort.indexed)
          _SortRow(
            title: edit.sheet.field(sort.column)!.title,
            sort: sort,
            first: index == 0,
            onFlip: () => controller.flipSort(index),
            onRaise: () => controller.raiseSort(index),
            onRemove: () => controller.removeSort(index),
          ),
        // The server takes up to five.
        if (edit.draft.sort.length < 5)
          ExportAddButton(
            icon: Icons.sort,
            label: l10n.exportAddSort,
            fields: [
              for (final f in edit.sheet.fields)
                if (!sorted.contains(f.key)) f,
            ],
            onPicked: controller.addSort,
          ),
      ],
    );
  }
}

class _SortRow extends StatelessWidget {
  const _SortRow({
    required this.title,
    required this.sort,
    required this.first,
    required this.onFlip,
    required this.onRaise,
    required this.onRemove,
  });

  final String title;
  final ExportSort sort;
  final bool first;
  final VoidCallback onFlip;
  final VoidCallback onRaise;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: onFlip,
          icon: Icon(
            sort.descending ? Icons.arrow_downward : Icons.arrow_upward,
          ),
          label: Text(
            sort.descending ? l10n.exportDescending : l10n.exportAscending,
          ),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.exportRaiseSort(title),
            onPressed: first ? null : onRaise,
            icon: const Icon(Icons.vertical_align_top),
          ),
          IconButton(
            tooltip: l10n.exportRemoveSort(title),
            onPressed: onRemove,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
