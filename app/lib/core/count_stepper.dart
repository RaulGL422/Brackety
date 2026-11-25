import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

/// "label  [−] value [+]": one tap per change, no keyboard. The buttons stop at [min] and [max].
/// Square buttons a thumb finds without looking, and the value large, as on the scoreboard.
class CountStepper extends StatelessWidget {
  const CountStepper({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.lessTooltip,
    required this.moreTooltip,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final String lessTooltip;
  final String moreTooltip;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final square = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.s),
    );
    Widget button(String tooltip, IconData icon, VoidCallback? onPressed) =>
        IconButton.filledTonal(
          tooltip: tooltip,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            shape: square,
            minimumSize: const Size.square(AppSizes.touchTarget),
          ),
          onPressed: onPressed,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        spacing: AppSpacing.s,
        children: [
          Expanded(child: Text(label, style: text.bodyLarge)),
          button(
            lessTooltip,
            Icons.remove,
            value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: text.headlineSmall,
              semanticsLabel: '$label $value',
            ),
          ),
          button(
            moreTooltip,
            Icons.add,
            value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
