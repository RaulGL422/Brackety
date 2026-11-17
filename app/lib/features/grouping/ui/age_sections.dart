import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/grouping_models.dart';

/// F2-2: a category may mix ages, but each participant shows up under their own age.
bool mixesAges(List<CategoryParticipant> participants) =>
    participants.map((p) => p.age).toSet().length > 1;

/// A heading per age, youngest first, each followed by its participants in the order given.
List<Object> withAgeHeadings(List<CategoryParticipant> sorted) {
  final byAge = <int, List<CategoryParticipant>>{};
  for (final p in sorted) {
    byAge.putIfAbsent(p.age, () => []).add(p);
  }
  return [
    for (final age in byAge.keys.toList()..sort()) ...[
      AgeHeading(age, byAge[age]!.length),
      ...byAge[age]!,
    ],
  ];
}

class AgeHeading {
  const AgeHeading(this.age, this.count);

  final int age;
  final int count;
}

class AgeHeadingTile extends StatelessWidget {
  const AgeHeadingTile({super.key, required this.heading});

  final AgeHeading heading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.m,
        AppSpacing.l,
        AppSpacing.xs,
      ),
      child: Semantics(
        header: true,
        child: Text(
          l10n.ageHeading(heading.age, heading.count),
          style: text.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Only when the category mixes ages: splits the list by age, or shows it whole.
class SplitByAgeChip extends StatelessWidget {
  const SplitByAgeChip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
    child: Align(
      alignment: Alignment.centerLeft,
      child: FilterChip(
        avatar: const Icon(Icons.cake_outlined),
        label: Text(AppLocalizations.of(context).splitByAge),
        selected: selected,
        onSelected: onSelected,
      ),
    ),
  );
}
