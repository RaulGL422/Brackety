import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

/// The other way out of a form, under a line: «¿Aún no tienes cuenta?» on the left and its button,
/// only as wide as its text, on the right (Raul, 2026-11-26): a full-width button would compete
/// with the form's own. When both do not fit on one row (a narrow phone, large text), the button
/// goes under the question.
class AuthAlternative extends StatelessWidget {
  const AuthAlternative({
    super.key,
    required this.question,
    required this.action,
    required this.onPressed,
  });

  final String question;
  final String action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.m),
        const Divider(),
        const SizedBox(height: AppSpacing.m),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.l,
          runSpacing: AppSpacing.s,
          children: [
            Text(
              question,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            OutlinedButton(onPressed: onPressed, child: Text(action)),
          ],
        ),
      ],
    );
  }
}
