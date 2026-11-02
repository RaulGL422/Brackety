import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';

// Phase 1 prototype accounts (docs/modulos/prototipo-f1.md); the password is the username.
const _demoAccounts = [
  'club1',
  'ayudante1',
  'ayudante2',
  'arbitro1',
  'arbitro2',
  'arbitro3',
  'arbitro4',
  'arbitro5',
];

/// Debug builds only: one tap signs in as a demo account.
class DemoAccounts extends StatelessWidget {
  const DemoAccounts({super.key, required this.onSelected});

  /// Null while a sign-in is running.
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    final onSelected = this.onSelected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLocalizations.of(context).loginDemoAccounts,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.s),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            for (final account in _demoAccounts)
              ActionChip(
                label: Text(account),
                onPressed: onSelected == null
                    ? null
                    : () => onSelected(account),
              ),
          ],
        ),
      ],
    );
  }
}
