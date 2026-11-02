import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';

/// Asks for confirmation and a reason before a warning or disqualification; null if cancelled.
Future<String?> askReason(BuildContext context, {required String title}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ReasonDialog(title: title),
  );
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.title});

  final String title;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.reasonConfirm),
          TextField(
            controller: _reason,
            autofocus: true,
            maxLength: 200,
            decoration: InputDecoration(labelText: l10n.reasonLabel),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _reason.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_reason.text.trim()),
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}
