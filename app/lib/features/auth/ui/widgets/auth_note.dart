import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

/// Short points that help with the next step, in a white box: «Si no lo ves, mira en spam».
class AuthNote extends StatelessWidget {
  const AuthNote({super.key, required this.items, this.title});

  final List<String> items;

  /// A lead-in line above the points, such as «Si entras con el QR:».
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = this.title;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            for (final (index, item) in items.indexed) ...[
              if (index > 0) const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Text('•', style: theme.textTheme.bodyLarge),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(child: Text(item, style: theme.textTheme.bodyLarge)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
