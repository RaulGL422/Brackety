import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.dashboardTitle, style: text.headlineMedium),
        const SizedBox(height: 8),
        Text(l10n.dashboardSubtitle, style: text.bodyLarge),
      ],
    );
  }
}
