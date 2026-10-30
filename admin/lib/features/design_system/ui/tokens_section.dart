import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';

class TypographySection extends StatelessWidget {
  const TypographySection({super.key});

  @override
  Widget build(BuildContext context) {
    final sample = AppLocalizations.of(context).dsTypeSample;
    final t = Theme.of(context).textTheme;
    final styles = {
      'displayLarge': t.displayLarge,
      'displayMedium': t.displayMedium,
      'displaySmall': t.displaySmall,
      'headlineLarge': t.headlineLarge,
      'headlineMedium': t.headlineMedium,
      'headlineSmall': t.headlineSmall,
      'titleLarge': t.titleLarge,
      'titleMedium': t.titleMedium,
      'titleSmall': t.titleSmall,
      'bodyLarge': t.bodyLarge,
      'bodyMedium': t.bodyMedium,
      'bodySmall': t.bodySmall,
      'labelLarge': t.labelLarge,
      'labelMedium': t.labelMedium,
      'labelSmall': t.labelSmall,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final MapEntry(key: name, value: style) in styles.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name · ${_family(style!)} ${style.fontSize!.round()}px · '
                  'w${style.fontWeight!.value}',
                  style: t.labelSmall!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(sample, style: style),
              ],
            ),
          ),
      ],
    );
  }

  static String _family(TextStyle style) =>
      style.fontFamily?.split('/').last ?? '';
}

class SpacingSection extends StatelessWidget {
  const SpacingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final label = Theme.of(context).textTheme.labelMedium;
    const spacing = {
      'xs': AppSpacing.xs,
      's': AppSpacing.s,
      'm': AppSpacing.m,
      'l': AppSpacing.l,
      'xl': AppSpacing.xl,
      'xxl': AppSpacing.xxl,
      'xxxl': AppSpacing.xxxl,
    };
    const radius = {
      's': AppRadius.s,
      'm': AppRadius.m,
      'l': AppRadius.l,
      'full': AppRadius.full,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final MapEntry(key: name, value: v) in spacing.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Text('$name · ${v.round()}', style: label),
                ),
                Container(width: v * 4, height: AppSpacing.m, color: c.primary),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.l),
        Wrap(
          spacing: AppSpacing.l,
          runSpacing: AppSpacing.m,
          children: [
            for (final MapEntry(key: name, value: r) in radius.entries)
              Container(
                width: 96,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.primaryContainer,
                  borderRadius: BorderRadius.circular(r),
                ),
                child: Text(
                  '$name · ${r == AppRadius.full ? '∞' : r.round()}',
                  style: label!.copyWith(color: c.onPrimaryContainer),
                ),
              ),
            Container(
              width: AppSizes.touchTarget,
              height: AppSizes.touchTarget,
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: c.outline)),
              child: Text('${AppSizes.touchTarget.round()}', style: label),
            ),
            Container(
              width: AppSizes.scoreTouchTarget,
              height: AppSizes.scoreTouchTarget,
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: c.outline)),
              child: Text('${AppSizes.scoreTouchTarget.round()}', style: label),
            ),
          ],
        ),
      ],
    );
  }
}
