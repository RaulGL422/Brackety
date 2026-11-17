import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';

/// Asks for confirmation and a reason before a warning or disqualification; null if cancelled.
/// [suggestions]: the event's warning reasons (F1-4). One tap on one gives it at once; a destructive action
/// (disqualification) only fills it in, to confirm. Another reason is typed below.
Future<String?> askReason(
  BuildContext context, {
  required String title,
  String? confirmLabel,
  String? dismissLabel,
  bool destructive = false,
  List<String> suggestions = const [],
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ReasonDialog(
      title: title,
      confirmLabel: confirmLabel,
      dismissLabel: dismissLabel,
      destructive: destructive,
      suggestions: suggestions,
    ),
  );
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({
    required this.title,
    this.confirmLabel,
    this.dismissLabel,
    this.destructive = false,
    this.suggestions = const [],
  });

  final String title;
  final String? confirmLabel;

  /// When "Cancelar" would be read as the action itself (cancelling a match).
  final String? dismissLabel;
  final bool destructive;
  final List<String> suggestions;

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
    final reason = _reason.text.trim();
    final picking = widget.suggestions.isNotEmpty;
    // Content scrolls and the two buttons share one row: with the keyboard up nothing overlaps
    // the field, and each label has half the width.
    return AlertDialog(
      scrollable: true,
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(picking ? l10n.reasonPick : l10n.reasonConfirm),
          const SizedBox(height: 12),
          for (final s in widget.suggestions)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    alignment: AlignmentDirectional.centerStart,
                    backgroundColor: s == reason
                        ? Theme.of(context).colorScheme.secondaryContainer
                        : null,
                  ),
                  onPressed: () {
                    if (widget.destructive) {
                      setState(() => _reason.text = s);
                    } else {
                      Navigator.of(context).pop(s);
                    }
                  },
                  child: Text(s),
                ),
              ),
            ),
          TextField(
            controller: _reason,
            // With reasons to tap, the keyboard would cover them.
            autofocus: !picking,
            maxLength: 200,
            decoration: InputDecoration(
              labelText: picking ? l10n.reasonOther : l10n.reasonLabel,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        Row(
          spacing: AppSpacing.s,
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  widget.dismissLabel ?? l10n.cancel,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              child: FilledButton(
                style: widget.destructive
                    ? FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      )
                    : null,
                onPressed: reason.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(reason),
                child: Text(
                  widget.confirmLabel ?? l10n.confirm,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
