import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';

/// Page title with a refresh button.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, required this.onRefresh});

  final String title;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ),
        const SizedBox(width: AppSpacing.s),
        IconButton(
          tooltip: AppLocalizations.of(context).refresh,
          icon: const Icon(Icons.refresh),
          onPressed: onRefresh,
        ),
      ],
    );
  }
}
