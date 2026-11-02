import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

/// One line of a desktop table (header or row): each cell takes its [flexes] share of the width,
/// so long values wrap instead of pushing the page sideways.
class TableLine extends StatelessWidget {
  const TableLine({super.key, required this.flexes, required this.cells})
    : assert(flexes.length == cells.length);

  final List<int> flexes;
  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.s,
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: flexes[i],
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: cells[i],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The header line of a [TableLine] table.
class TableHeader extends StatelessWidget {
  const TableHeader({super.key, required this.flexes, required this.labels});

  final List<int> flexes;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    return TableLine(
      flexes: flexes,
      cells: [for (final label in labels) Text(label, style: style)],
    );
  }
}
