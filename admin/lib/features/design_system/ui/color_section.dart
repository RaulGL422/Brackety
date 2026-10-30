import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';

class ColorSection extends StatelessWidget {
  const ColorSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).colorScheme;
    final b = BracketyColors.of(context);
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.dsContrastHint, style: text.bodySmall),
        const SizedBox(height: AppSpacing.m),
        _Swatches([
          ('primary', c.primary, c.onPrimary),
          ('primaryContainer', c.primaryContainer, c.onPrimaryContainer),
          ('secondary', c.secondary, c.onSecondary),
          ('secondaryContainer', c.secondaryContainer, c.onSecondaryContainer),
          ('tertiary', c.tertiary, c.onTertiary),
          ('tertiaryContainer', c.tertiaryContainer, c.onTertiaryContainer),
          ('error', c.error, c.onError),
          ('errorContainer', c.errorContainer, c.onErrorContainer),
          ('surface', c.surface, c.onSurface),
          ('surface · variant', c.surface, c.onSurfaceVariant),
          ('surfaceContainer', c.surfaceContainer, c.onSurface),
          ('surfaceContainerHighest', c.surfaceContainerHighest, c.onSurface),
          ('inverseSurface', c.inverseSurface, c.onInverseSurface),
          ('outline', c.surface, c.outline),
        ]),
        const SizedBox(height: AppSpacing.l),
        Text(l10n.dsStatusColors, style: text.titleMedium),
        const SizedBox(height: AppSpacing.s),
        _Swatches([
          ('success', b.success, b.onSuccess),
          ('successContainer', b.successContainer, b.onSuccessContainer),
          ('warning', b.warning, b.onWarning),
          ('warningContainer', b.warningContainer, b.onWarningContainer),
        ]),
        const SizedBox(height: AppSpacing.l),
        Text(l10n.dsCompetitorColors, style: text.titleMedium),
        const SizedBox(height: AppSpacing.s),
        _Swatches([
          for (final color in CompetitorColor.values)
            (color.name, color.color, color.onColor),
        ]),
      ],
    );
  }
}

class _Swatches extends StatelessWidget {
  const _Swatches(this.items);

  final List<(String, Color, Color)> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      children: [
        for (final (name, bg, fg) in items) _Swatch(name: name, bg: bg, fg: fg),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.bg, required this.fg});

  final String name;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: 176,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: DefaultTextStyle(
        style: text.bodySmall!.copyWith(color: fg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: text.titleSmall!.copyWith(color: fg)),
            Text('${_hex(bg)} / ${_hex(fg)}'),
            _ContrastBadge(contrastRatio(bg, fg)),
          ],
        ),
      ),
    );
  }

  static String _hex(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}

class _ContrastBadge extends StatelessWidget {
  const _ContrastBadge(this.ratio);

  final double ratio;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final verdict = ratio >= 4.5
        ? 'AA'
        : ratio >= 3
        ? l10n.dsContrastLarge
        : '✗';
    return Text('${ratio.toStringAsFixed(1)}:1 · $verdict');
  }
}
