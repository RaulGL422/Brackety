import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

/// A result line under a form: an error, or a success that does not rely on colour alone (it has an icon).
class FormMessage extends StatelessWidget {
  const FormMessage.error(this.text, {super.key}) : success = false;

  const FormMessage.success(this.text, {super.key}) : success = true;

  final String text;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final color = success
        ? BracketyColors.of(context).success
        : Theme.of(context).colorScheme.error;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          success ? Icons.check_circle_outline : Icons.error_outline,
          color: color,
        ),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: Text(text, style: TextStyle(color: color)),
        ),
      ],
    );
  }
}
