import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../mat/ui/fighter_text.dart';
import '../data/match_view.dart';
import 'undo_text.dart';

/// Every action of a match, oldest first: who, what, when and at which match time. For the
/// referee ([markNextUndo]) the one that Undo would take back next is marked.
class TimelineList extends StatelessWidget {
  const TimelineList({
    super.key,
    required this.view,
    this.controller,
    this.markNextUndo = false,
  });

  final MatchView view;
  final ScrollController? controller;
  final bool markNextUndo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final time = DateFormat.Hms(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final nextUndo = markNextUndo ? view.lastUndoable : null;
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.all(AppSpacing.l),
      itemCount: view.timeline.length,
      itemBuilder: (context, i) {
        final e = view.timeline[i];
        final who = switch (e.side) {
          Side.red => '${l10n.cornerRed} · ${view.red.title(l10n)}',
          Side.blue => '${l10n.cornerBlue} · ${view.blue.title(l10n)}',
          null => null,
        };
        final next = nextUndo != null && e.id == nextUndo.id;
        final notes = [
          ?who,
          if (e.delta case final delta?) l10n.clockAdjustBy(signedSeconds(delta)),
          ?e.reason,
          if (e.gaveRivalPoint) l10n.tlRivalPoint,
          if (e.automatic) l10n.tlAutomatic,
          if (e.undone) l10n.tlUndone,
          if (next) l10n.tlNextUndo,
          ?e.actor,
        ];
        return ListTile(
          dense: true,
          selected: next,
          leading: Text(clockText(e.clock)),
          title: Text(
            actionLabel(l10n, e.action),
            style: e.undone
                ? const TextStyle(decoration: TextDecoration.lineThrough)
                : next
                ? const TextStyle(fontWeight: FontWeight.bold)
                : null,
          ),
          subtitle: Text(notes.join(' · ')),
          trailing: next
              ? const Icon(Icons.undo)
              : Text(time.format(e.at.toLocal())),
        );
      },
    );
  }
}

String actionLabel(AppLocalizations l10n, MatchAction action) =>
    switch (action) {
      MatchAction.start => l10n.tlStart,
      MatchAction.stop => l10n.tlStop,
      MatchAction.point => l10n.tlPoint,
      MatchAction.pointRemoved => l10n.tlPointRemoved,
      MatchAction.clockAdjust => l10n.tlClockAdjust,
      MatchAction.warning => l10n.actionWarning,
      MatchAction.oneHandWarning => l10n.actionOneHand,
      MatchAction.disqualification => l10n.actionDisqualify,
      MatchAction.undo => l10n.tlUndo,
      MatchAction.finish => l10n.tlFinish,
    };

String? sideLabel(AppLocalizations l10n, Side? side) => switch (side) {
  Side.red => l10n.cornerRed,
  Side.blue => l10n.cornerBlue,
  null => null,
};
