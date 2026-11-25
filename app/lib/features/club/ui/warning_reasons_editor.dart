import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/club_repository.dart';
import '../data/event_settings.dart';
import '../state/club_providers.dart';

/// The warning reasons the referee picks with one tap (F1-4): the sport's until the club changes them. Saved at
/// once, as the rest of the settings. "Otro" is always there on the scoreboard.
class WarningReasonsEditor extends ConsumerStatefulWidget {
  const WarningReasonsEditor({
    super.key,
    required this.eventId,
    required this.settings,
  });

  final String eventId;
  final EventSettings settings;

  @override
  ConsumerState<WarningReasonsEditor> createState() =>
      _WarningReasonsEditorState();
}

class _WarningReasonsEditorState extends ConsumerState<WarningReasonsEditor> {
  late List<String>? _own = widget.settings.ownWarningReasons;
  final _new = TextEditingController();
  var _saving = false;

  List<String> get _shown => _own ?? widget.settings.sportWarningReasons;

  @override
  void dispose() {
    _new.dispose();
    super.dispose();
  }

  /// Null goes back to the sport's list.
  Future<void> _save(List<String>? reasons) async {
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    final savedText = CoreLocalizations.of(context).saved;
    final before = _own;
    setState(() {
      _own = reasons;
      _saving = true;
    });
    try {
      await ref
          .read(clubRepositoryProvider)
          .saveWarningReasons(widget.eventId, reasons);
      ref.invalidate(eventSettingsProvider(widget.eventId));
      toasts.show(savedText, duration: const Duration(seconds: 1));
    } on DioException {
      if (mounted) setState(() => _own = before);
      toasts.show(l10n.saveError, kind: ToastKind.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _add() {
    final reason = _new.text.trim();
    if (reason.isEmpty) return;
    final exists = _shown.any((r) => r.toLowerCase() == reason.toLowerCase());
    _new.clear();
    if (!exists) _save([..._shown, reason]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final full = _shown.length >= maxWarningReasons;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _own == null ? l10n.warningReasonsSportHint : l10n.warningReasonsHint,
        ),
        const SizedBox(height: AppSpacing.s),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            for (final r in _shown)
              InputChip(
                label: Text(r),
                onDeleted: _saving
                    ? null
                    : () => _save([
                        for (final o in _shown)
                          if (o != r) o,
                      ]),
                deleteButtonTooltipMessage: l10n.warningReasonsRemove(r),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _new,
                enabled: !_saving && !full,
                maxLength: 60,
                decoration: InputDecoration(
                  labelText: full
                      ? l10n.warningReasonsFull(maxWarningReasons)
                      : l10n.warningReasonsAdd,
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s),
              child: FilledButton.tonal(
                onPressed: _saving || full ? null : _add,
                child: Text(l10n.warningReasonsAddButton),
              ),
            ),
          ],
        ),
        if (_own != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: _saving ? null : () => _save(null),
              child: Text(l10n.warningReasonsUseSport),
            ),
          ),
      ],
    );
  }
}
