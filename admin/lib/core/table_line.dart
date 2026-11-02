import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

/// Narrower than this, the lists show cards: the table columns would clip their chips and
/// buttons. Measured against the list's own width (rail and padding already taken), so an 840
/// window with the extended rail gets cards and a 1280 one gets the table.
const tableMinWidth = 960.0;

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

/// A table value that never wraps mid-word (emails, names): one line with an ellipsis, the full
/// value in a tooltip.
class OneLineText extends StatelessWidget {
  const OneLineText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: text,
      child: Text(
        text,
        style: style,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
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
