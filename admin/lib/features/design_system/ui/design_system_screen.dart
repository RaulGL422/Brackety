import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import 'color_section.dart';
import 'components_section.dart';
import 'samples_section.dart';
import 'tokens_section.dart';

/// Debug-only preview of the design system, to validate it visually.
class DesignSystemScreen extends StatefulWidget {
  const DesignSystemScreen({super.key});

  @override
  State<DesignSystemScreen> createState() => _DesignSystemScreenState();
}

class _DesignSystemScreenState extends State<DesignSystemScreen> {
  Brightness? _brightness;
  var _textScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brightness = _brightness ?? MediaQuery.platformBrightnessOf(context);
    final theme = buildTheme(brightness);

    return Theme(
      data: theme,
      child: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(_textScale)),
        child: Material(
          color: theme.colorScheme.surface,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.l),
                children: [
                  Text(l10n.dsTitle, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.dsIntro, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.l),
                  _controls(l10n, brightness),
                  _Section(
                    title: l10n.dsSamples,
                    child: const SamplesSection(),
                  ),
                  _Section(title: l10n.dsColors, child: const ColorSection()),
                  _Section(
                    title: l10n.dsTypography,
                    child: const TypographySection(),
                  ),
                  _Section(
                    title: '${l10n.dsSpacing} · ${l10n.dsRadius}',
                    child: const SpacingSection(),
                  ),
                  _Section(
                    title: l10n.dsComponents,
                    child: const ComponentsSection(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _controls(AppLocalizations l10n, Brightness brightness) {
    return Wrap(
      spacing: AppSpacing.l,
      runSpacing: AppSpacing.m,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SegmentedButton<Brightness>(
          segments: [
            ButtonSegment(
              value: Brightness.light,
              icon: const Icon(Icons.light_mode_outlined),
              label: Text(l10n.dsModeLight),
            ),
            ButtonSegment(
              value: Brightness.dark,
              icon: const Icon(Icons.dark_mode_outlined),
              label: Text(l10n.dsModeDark),
            ),
          ],
          selected: {brightness},
          onSelectionChanged: (s) => setState(() => _brightness = s.first),
        ),
        SizedBox(
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.dsTextScale((_textScale * 100).round())),
              Slider(
                value: _textScale,
                min: 1,
                max: 2,
                divisions: 4,
                onChanged: (v) => setState(() => _textScale = v),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const Divider(height: AppSpacing.xl),
          child,
        ],
      ),
    );
  }
}
