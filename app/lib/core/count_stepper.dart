import 'package:flutter/material.dart';

/// "label  − value +": one tap per change, no keyboard. The buttons stop at [min] and [max].
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
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label)),
      IconButton(
        tooltip: lessTooltip,
        icon: const Icon(Icons.remove_circle_outline),
        onPressed: value > min ? () => onChanged(value - 1) : null,
      ),
      SizedBox(
        width: 32,
        child: Text(
          '$value',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
          semanticsLabel: '$label $value',
        ),
      ),
      IconButton(
        tooltip: moreTooltip,
        icon: const Icon(Icons.add_circle_outline),
        onPressed: value < max ? () => onChanged(value + 1) : null,
      ),
    ],
  );
}
