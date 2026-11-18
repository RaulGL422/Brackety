import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';

/// On top of a grouping screen for whoever may only look (F1-7 C).
class ReadOnlyNotice extends StatelessWidget {
  const ReadOnlyNotice({super.key});

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerHigh,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined, size: 20),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(AppLocalizations.of(context).permissionsReadOnly),
          ),
        ],
      ),
    ),
  );
}
