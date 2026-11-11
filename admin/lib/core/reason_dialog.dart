import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';

/// Asks why before an event operation (it goes to the audit). With [typeToConfirm], the
/// confirm button waits until that text is typed too. Returns the reason, or null if cancelled.
Future<String?> askReason(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  String? typeToConfirm,
}) => showDialog<String>(
  context: context,
  builder: (_) => ReasonDialog(
    title: title,
    body: body,
    confirmLabel: confirmLabel,
    typeToConfirm: typeToConfirm,
  ),
);

class ReasonDialog extends StatefulWidget {
  const ReasonDialog({
    super.key,
    required this.title,
    required this.body,
    required this.confirmLabel,
    this.typeToConfirm,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final String? typeToConfirm;

  @override
  State<ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<ReasonDialog> {
  final _reason = TextEditingController();
  final _typed = TextEditingController();

  bool get _ready =>
      _reason.text.trim().isNotEmpty &&
      (widget.typeToConfirm == null ||
          _typed.text.trim() == widget.typeToConfirm!.trim());

  @override
  void dispose() {
    _reason.dispose();
    _typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      actionsOverflowDirection: VerticalDirection.up,
      actionsOverflowButtonSpacing: 8,
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.formMaxWidth),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.m,
            children: [
              Text(widget.body),
              TextField(
                controller: _reason,
                autofocus: true,
                maxLength: 300,
                decoration: InputDecoration(
                  labelText: l10n.reasonLabel,
                  helperText: l10n.reasonHelper,
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (widget.typeToConfirm case final name?)
                TextField(
                  controller: _typed,
                  decoration: InputDecoration(
                    labelText: l10n.typeToConfirm(name),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: _ready
              ? () => Navigator.pop(context, _reason.text.trim())
              : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
