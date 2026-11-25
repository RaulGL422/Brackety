import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../core/count_stepper.dart';
import '../../../l10n/gen/app_localizations.dart';

/// A category's groups (GR-5): from [min] to [max] members, wildcards included, and whether
/// everyone fights everyone twice. One tap per change, no keyboard.
class CategoryGroupsField extends StatelessWidget {
  const CategoryGroupsField({
    super.key,
    required this.min,
    required this.max,
    required this.returnLeg,
    required this.onChanged,
  });

  /// The sizes the server accepts.
  static const smallest = 2;
  static const largest = 8;

  final int min;
  final int max;
  final bool returnLeg;
  final void Function(int min, int max, bool returnLeg) onChanged;

  // The two ends push each other: "from" never goes above "to".
  void _setMin(int value) =>
      onChanged(value, value > max ? value : max, returnLeg);

  void _setMax(int value) =>
      onChanged(value < min ? value : min, value, returnLeg);

  Widget _stepper(
    String label,
    int value,
    ValueChanged<int> onChanged,
    AppLocalizations l10n,
  ) => CountStepper(
    label: label,
    value: value,
    min: smallest,
    max: largest,
    lessTooltip: l10n.categoryGroupLess(label),
    moreTooltip: l10n.categoryGroupMore(label),
    onChanged: onChanged,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final matches = max * (max - 1) ~/ 2 * (returnLeg ? 2 : 1);
    // One block: what a group of this category is, and what it costs in matches.
    // A Material, not a coloured box: the switch's tap ripple paints on it.
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.m),
      child: Material(
        type: MaterialType.transparency,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.m,
            AppSpacing.s,
            AppSpacing.m,
            AppSpacing.m,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.categoryGroups, style: text.titleMedium),
              _stepper(l10n.categoryGroupFrom, min, _setMin, l10n),
              _stepper(l10n.categoryGroupTo, max, _setMax, l10n),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.categoryReturnLeg),
                value: returnLeg,
                onChanged: (on) => onChanged(min, max, on),
              ),
              Text(
                l10n.categoryGroupMatches(max, matches),
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
