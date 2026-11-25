import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

/// The other way out of a form, under a line: «¿Aún no tienes cuenta?» and its button.
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
        Text(
          question,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        OutlinedButton(onPressed: onPressed, child: Text(action)),
      ],
    );
  }
}
