import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../data/legal_structure.dart';
import 'external_link.dart';

/// A table of a legal text. On a phone each row is a block: its first cell in bold, the others
/// under it as «Column: value», so nothing scrolls sideways (Raul, 2026-11-25).
class LegalTableView extends StatelessWidget {
  const LegalTableView({super.key, required this.table, required this.style});

  final LegalTable table;
  final MarkdownStyleSheet style;

  @override
  Widget build(BuildContext context) {
    final rule = BorderSide(
      color: Theme.of(context).colorScheme.outlineVariant,
    );
    return WindowSize.of(context) == WindowSize.compact
        ? _blocks(rule)
        : _table(context, rule);
  }

  Widget _cell(String markdown, {MarkdownStyleSheet? style}) => MarkdownBody(
    data: markdown,
    styleSheet: style ?? this.style,
    onTapLink: (_, href, _) => openExternalLink(href),
  );

  Widget _blocks(BorderSide rule) {
    final strong = style.copyWith(
      p: style.p?.copyWith(fontWeight: FontWeight.w700),
    );
    final quiet = style.copyWith(p: style.tableBody);
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(top: rule)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final row in table.rows)
            DecoratedBox(
              decoration: BoxDecoration(border: Border(bottom: rule)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.xs,
                  children: [
                    _cell(row.first, style: strong),
                    for (var i = 1; i < row.length; i++)
                      _cell('${table.header[i]}: ${row[i]}', style: quiet),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _table(BuildContext context, BorderSide rule) {
    final ink = BorderSide(
      color: Theme.of(context).colorScheme.onSurface,
      width: 2,
    );
    final head = style.copyWith(
      p: style.p?.copyWith(fontWeight: FontWeight.w800),
    );
    final quiet = style.copyWith(p: style.tableBody);
    TableRow row(List<String> cells, {required bool header}) => TableRow(
      decoration: BoxDecoration(border: Border(bottom: header ? ink : rule)),
      children: [
        for (var i = 0; i < cells.length; i++)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              0,
              AppSpacing.s,
              AppSpacing.m,
              AppSpacing.s,
            ),
            child: _cell(
              cells[i],
              style: header ? head : (i == 0 ? null : quiet),
            ),
          ),
      ],
    );
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: [
        row(table.header, header: true),
        for (final cells in table.rows) row(cells, header: false),
      ],
    );
  }
}
