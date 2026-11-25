import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/export_models.dart';

/// One filter: values separated by commas, or a range for a number column.
class ExportFilterRow extends StatefulWidget {
  const ExportFilterRow({
    super.key,
    required this.field,
    required this.filter,
    required this.onChanged,
    required this.onRemove,
  });

  final ExportField field;
  final ExportFilter filter;
  final ValueChanged<ExportFilter> onChanged;
  final VoidCallback onRemove;

  @override
  State<ExportFilterRow> createState() => _ExportFilterRowState();
}

class _ExportFilterRowState extends State<ExportFilterRow> {
  late final _values = TextEditingController(
    text: widget.filter.anyOf.join(', '),
  );
  late final _min = TextEditingController(
    text: widget.filter.min?.toString() ?? '',
  );
  late final _max = TextEditingController(
    text: widget.filter.max?.toString() ?? '',
  );

  @override
  void dispose() {
    _values.dispose();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _send() => widget.onChanged(
    ExportFilter(
      column: widget.field.key,
      anyOf: [
        for (final v in _values.text.split(','))
          if (v.trim().isNotEmpty) v.trim(),
      ],
      min: _number(_min.text),
      max: _number(_max.text),
    ),
  );

  // A decimal comma as Spanish speakers write it.
  static num? _number(String text) =>
      num.tryParse(text.trim().replaceAll(',', '.'));

  Widget _range(AppLocalizations l10n) {
    const number = TextInputType.numberWithOptions(decimal: true, signed: true);
    return Wrap(
      spacing: AppSpacing.m,
      runSpacing: AppSpacing.s,
      children: [
        SizedBox(
          width: AppSizes.compactTableColumnWidth,
          child: TextField(
            controller: _min,
            keyboardType: number,
            decoration: InputDecoration(labelText: l10n.exportFilterMin),
            onChanged: (_) => _send(),
          ),
        ),
        SizedBox(
          width: AppSizes.compactTableColumnWidth,
          child: TextField(
            controller: _max,
            keyboardType: number,
            decoration: InputDecoration(labelText: l10n.exportFilterMax),
            onChanged: (_) => _send(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.field.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                tooltip: l10n.exportRemoveFilter(widget.field.title),
                onPressed: widget.onRemove,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          if (widget.field.kind.isNumber)
            _range(l10n)
          else
            TextField(
              controller: _values,
              decoration: InputDecoration(labelText: l10n.exportFilterValues),
              onChanged: (_) => _send(),
            ),
        ],
      ),
    );
  }
}
