import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

/// A group's number on ink (docs/07-diseno.md: groups are told apart by number, never by a colour a
/// competitor may wear), large enough to find from across the table. Its label goes on the card.
class GroupNumber extends StatelessWidget {
  const GroupNumber({super.key, required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final colors = BracketyColors.of(context);
    return ExcludeSemantics(
      child: Container(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.band,
          borderRadius: BorderRadius.circular(AppRadius.s),
        ),
        child: Text(
          '$number',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(color: colors.onBand),
        ),
      ),
    );
  }
}
