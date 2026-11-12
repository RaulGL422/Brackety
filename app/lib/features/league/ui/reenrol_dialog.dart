import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/async_view.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../club/data/club_models.dart';
import '../../club/state/club_providers.dart';
import '../data/league_models.dart';
import '../data/league_repository.dart';
import '../state/league_providers.dart';

/// Enters people of the league's other phases in this one, with their latest data.
Future<void> showReenrolDialog(BuildContext context, String eventId) =>
    showDialog<void>(
      context: context,
      builder: (_) => _ReenrolDialog(eventId: eventId),
    );

class _ReenrolDialog extends ConsumerStatefulWidget {
  const _ReenrolDialog({required this.eventId});

  final String eventId;

  @override
  ConsumerState<_ReenrolDialog> createState() => _ReenrolDialogState();
}

class _ReenrolDialogState extends ConsumerState<_ReenrolDialog> {
  final _selected = <String>{};
  var _filter = '';
  var _consent = false;
  var _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = leagueCandidatesProvider(widget.eventId);
    final candidates = ref.watch(provider).value ?? const <LeagueCandidate>[];
    final minorsSelected = candidates.any(
      (c) => _selected.contains(c.personId) && c.age < adultAge,
    );
    return AlertDialog(
      actionsOverflowDirection: VerticalDirection.up,
      actionsOverflowButtonSpacing: 8,
      title: Text(l10n.reenrolTitle),
      content: SizedBox(
        width: 480,
        height: 520,
        child: AsyncView(
          value: ref.watch(provider),
          onRetry: () => ref.invalidate(provider),
          data: (candidates) => candidates.isEmpty
              ? Text(l10n.reenrolEmpty)
              : _list(candidates, minorsSelected: minorsSelected),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed:
              _saving || _selected.isEmpty || (minorsSelected && !_consent)
              ? null
              : _save,
          child: Text(l10n.reenrolConfirm(_selected.length)),
        ),
      ],
    );
  }

  Widget _list(
    List<LeagueCandidate> candidates, {
    required bool minorsSelected,
  }) {
    final l10n = AppLocalizations.of(context);
    final filter = _filter.trim().toLowerCase();
    final visible = [
      for (final c in candidates)
        if (filter.isEmpty ||
            '${c.firstName} ${c.lastName} ${c.categoryName ?? ''} ${c.organizationName ?? ''}'
                .toLowerCase()
                .contains(filter))
          c,
    ];
    final allVisibleSelected = visible.every(
      (c) => _selected.contains(c.personId),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.reenrolHint),
        const SizedBox(height: AppSpacing.s),
        TextField(
          decoration: InputDecoration(
            labelText: l10n.reenrolSearch,
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => _filter = v),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(l10n.reenrolSelectAll(visible.length)),
          value: visible.isNotEmpty && allVisibleSelected,
          onChanged: visible.isEmpty
              ? null
              : (all) => setState(() {
                  for (final c in visible) {
                    all!
                        ? _selected.add(c.personId)
                        : _selected.remove(c.personId);
                  }
                }),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            children: [
              for (final c in visible)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _selected.contains(c.personId),
                  onChanged: (v) => setState(
                    () => v!
                        ? _selected.add(c.personId)
                        : _selected.remove(c.personId),
                  ),
                  title: Text('${c.firstName} ${c.lastName}'),
                  subtitle: Text(
                    [
                      l10n.participantAgeCategory(
                        c.age,
                        c.categoryName ?? l10n.noCategory,
                      ),
                      ?c.organizationName,
                      l10n.reenrolLastPhase(c.lastPhase),
                    ].join(' · '),
                  ),
                ),
            ],
          ),
        ),
        if (minorsSelected) ...[
          const Divider(height: 1),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(l10n.reenrolGuardianConsent),
            value: _consent,
            onChanged: (v) => setState(() => _consent = v!),
          ),
        ],
      ],
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    setState(() => _saving = true);
    try {
      final added = await ref
          .read(leagueRepositoryProvider)
          .reenrol(
            widget.eventId,
            _selected.toList(),
            guardianConsent: _consent,
          );
      ref
        ..invalidate(participantsProvider(widget.eventId))
        ..invalidate(leagueCandidatesProvider(widget.eventId))
        ..invalidate(leagueProvider(widget.eventId))
        ..invalidate(standingsProvider(widget.eventId));
      if (mounted) Navigator.pop(context);
      toasts.show(l10n.reenrolDone(added), kind: ToastKind.success);
    } on DioException {
      if (mounted) setState(() => _saving = false);
      toasts.show(l10n.saveError, kind: ToastKind.error);
    }
  }
}
