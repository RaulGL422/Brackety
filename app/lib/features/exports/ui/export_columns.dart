import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/export_models.dart';
import '../state/export_controller.dart';
import 'export_sections.dart';

/// The chosen columns in their order: drag, or the up and down buttons; the title, to rename it.
class ColumnsEditor extends ConsumerWidget {
  const ColumnsEditor(this.edit, {super.key});

  final ExportEdit edit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(exportDraftProvider(edit.eventId).notifier);
    final unchosen = [
      for (final f in edit.sheet.fields)
        if (!edit.draft.columns.contains(f.key)) f,
    ];
    return ExportSection(
      title: l10n.exportStepColumns,
      help: l10n.exportColumnsHelp,
      children: [
        if (edit.draft.columns.isEmpty) Text(l10n.exportNoColumns),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: controller.moveColumn,
          children: [
            for (final (index, key) in edit.draft.columns.indexed)
              _ColumnTile(
                key: ValueKey(key),
                index: index,
                last: index == edit.draft.columns.length - 1,
                field: edit.sheet.field(key)!,
                title: edit.draft.titles[key],
                eventId: edit.eventId,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        ExportAddButton(
          icon: Icons.add,
          label: l10n.exportAddColumn,
          fields: unchosen,
          onPicked: controller.addColumn,
        ),
      ],
    );
  }
}

class _ColumnTile extends ConsumerWidget {
  const _ColumnTile({
    super.key,
    required this.index,
    required this.last,
    required this.field,
    required this.title,
    required this.eventId,
  });

  final int index;
  final bool last;
  final ExportField field;
  final String? title;
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(exportDraftProvider(eventId).notifier);
    final shown = title ?? field.title;
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: ReorderableDragStartListener(
          index: index,
          child: const SizedBox.square(
            dimension: AppSizes.touchTarget,
            child: Icon(Icons.drag_indicator),
          ),
        ),
        title: Tooltip(
          message: l10n.exportRename(shown),
          child: InkWell(
            onTap: () => _rename(context, controller),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizes.touchTarget,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(shown),
              ),
            ),
          ),
        ),
        subtitle: field.isPersonal ? _PersonalMark(field.sensitivity) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.exportMoveUp(shown),
              onPressed: index == 0
                  ? null
                  : () => controller.moveColumn(index, index - 1),
              icon: const Icon(Icons.arrow_upward),
            ),
            IconButton(
              tooltip: l10n.exportMoveDown(shown),
              onPressed: last
                  ? null
                  : () => controller.moveColumn(index, index + 1),
              icon: const Icon(Icons.arrow_downward),
            ),
            IconButton(
              tooltip: l10n.exportRemove(shown),
              onPressed: () => controller.removeColumn(field.key),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(
    BuildContext context,
    ExportDraftController controller,
  ) async {
    final renamed = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(original: field.title, current: title),
    );
    if (renamed != null) controller.rename(field.key, renamed);
  }
}

/// The column's own title; empty, the sheet's. Owns its text so it lives as long as the dialog does.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.original, required this.current});

  final String original;
  final String? current;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _text = TextEditingController(text: widget.current ?? '');

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.exportRenameTitle),
      content: TextField(
        controller: _text,
        autofocus: true,
        maxLength: 80,
        decoration: InputDecoration(
          hintText: widget.original,
          helperText: l10n.exportRenameHelp(widget.original),
        ),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _text.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// Personal data or data about minors, in a word with its icon (docs/06-legal-rgpd.md).
class _PersonalMark extends StatelessWidget {
  const _PersonalMark(this.sensitivity);

  final Sensitivity sensitivity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(Icons.shield_outlined, size: AppSpacing.l, color: color),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            sensitivity == Sensitivity.minors
                ? l10n.exportMinors
                : l10n.exportPersonal,
            style: TextStyle(color: color),
          ),
        ),
      ],
    );
  }
}
