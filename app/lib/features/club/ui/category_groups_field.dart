import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final matches = max * (max - 1) ~/ 2 * (returnLeg ? 2 : 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.m),
        Text(l10n.categoryGroups, style: text.titleSmall),
        _Stepper(label: l10n.categoryGroupFrom, value: min, onChanged: _setMin),
        _Stepper(label: l10n.categoryGroupTo, value: max, onChanged: _setMax),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.categoryReturnLeg),
          value: returnLeg,
          onChanged: (on) => onChanged(min, max, on),
        ),
        Text(l10n.categoryGroupMatches(max, matches), style: text.bodySmall),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton.filledTonal(
          tooltip: l10n.categoryGroupLess(label),
          icon: const Icon(Icons.remove),
          onPressed: value > CategoryGroupsField.smallest
              ? () => onChanged(value - 1)
              : null,
        ),
        SizedBox(
          width: 48,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
            semanticsLabel: '$label $value',
          ),
        ),
        IconButton.filledTonal(
          tooltip: l10n.categoryGroupMore(label),
          icon: const Icon(Icons.add),
          onPressed: value < CategoryGroupsField.largest
              ? () => onChanged(value + 1)
              : null,
        ),
      ],
    );
  }
}
