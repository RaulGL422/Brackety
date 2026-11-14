import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// Asks whether to cancel a pending deletion; pops true to restore.
class RestoreAccountDialog extends StatelessWidget {
  const RestoreAccountDialog({super.key, required this.deletesOn});

  final DateTime deletesOn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat.yMMMMd(locale).format(deletesOn);
    return AlertDialog(
      scrollable: true,
      actionsOverflowDirection: VerticalDirection.up,
      actionsOverflowButtonSpacing: 8,
      title: Text(l10n.restoreTitle),
      content: Text(l10n.restoreBody(date)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.restoreConfirm),
        ),
      ],
    );
  }
}
