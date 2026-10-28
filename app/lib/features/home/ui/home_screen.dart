import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.homeWelcome, style: text.headlineMedium),
        const SizedBox(height: 8),
        Text(l10n.homeSubtitle, style: text.bodyLarge),
      ],
    );
  }
}
