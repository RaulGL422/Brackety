import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';

class ComponentsSection extends StatefulWidget {
  const ComponentsSection({super.key});

  @override
  State<ComponentsSection> createState() => _ComponentsSectionState();
}

class _ComponentsSectionState extends State<ComponentsSection> {
  var _notifications = true;
  var _category = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categories = [
      l10n.dsCategoryKids,
      l10n.dsCategoryCadet,
      l10n.dsCategorySenior,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            FilledButton(onPressed: () {}, child: Text(l10n.dsSave)),
            FilledButton.tonalIcon(
              onPressed: () {},
              icon: const Icon(Icons.how_to_reg_outlined),
              label: Text(l10n.dsTonal),
            ),
            OutlinedButton(onPressed: () {}, child: Text(l10n.dsCancel)),
            TextButton(onPressed: () {}, child: Text(l10n.dsMore)),
            FilledButton(onPressed: null, child: Text(l10n.dsDisabled)),
          ],
        ),
        const SizedBox(height: AppSpacing.l),
        Wrap(
          spacing: AppSpacing.l,
          runSpacing: AppSpacing.m,
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                decoration: InputDecoration(
                  labelText: l10n.dsFieldLabel,
                  hintText: l10n.dsFieldHint,
                ),
              ),
            ),
            SizedBox(
              width: 320,
              child: TextField(
                decoration: InputDecoration(
                  labelText: l10n.dsFieldLabel,
                  errorText: l10n.dsFieldError,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.l),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final (i, label) in categories.indexed)
              ChoiceChip(
                label: Text(label),
                selected: _category == i,
                onSelected: (_) => setState(() => _category = i),
              ),
            const _StatusBadges(),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        SizedBox(
          width: 360,
          child: SwitchListTile(
            title: Text(l10n.dsNotifications),
            value: _notifications,
            onChanged: (v) => setState(() => _notifications = v),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        SizedBox(
          width: 420,
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.emoji_events_outlined),
              title: Text(l10n.dsCardTitle),
              subtitle: Text(l10n.dsCardSubtitle),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        const LinearProgressIndicator(value: 0.6),
      ],
    );
  }
}

class _StatusBadges extends StatelessWidget {
  const _StatusBadges();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final b = BracketyColors.of(context);
    final c = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.s,
      children: [
        _Badge(l10n.dsPaid, b.successContainer, b.onSuccessContainer),
        _Badge(l10n.dsPending, b.warningContainer, b.onWarningContainer),
        _Badge(l10n.dsRejected, c.errorContainer, c.onErrorContainer),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.bg, this.fg);

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge!.copyWith(color: fg),
      ),
    );
  }
}
