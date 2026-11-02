import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../mat/ui/fighter_text.dart';
import '../data/match_view.dart';

/// Every action of a match, oldest first: who, what, when and at which match time.
class TimelineList extends StatelessWidget {
  const TimelineList({super.key, required this.view, this.controller});

  final MatchView view;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final time = DateFormat.Hms(
      Localizations.localeOf(context).toLanguageTag(),
    );
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
        final notes = [
          ?who,
          ?e.reason,
          if (e.gaveRivalPoint) l10n.tlRivalPoint,
          if (e.automatic) l10n.tlAutomatic,
          if (e.undone) l10n.tlUndone,
          ?e.actor,
        ];
        return ListTile(
          dense: true,
          leading: Text(_clock(e.clock)),
          title: Text(
            _label(l10n, e.action),
            style: e.undone
                ? const TextStyle(decoration: TextDecoration.lineThrough)
                : null,
          ),
          subtitle: Text(notes.join(' · ')),
          trailing: Text(time.format(e.at.toLocal())),
        );
      },
    );
  }

  static String _clock(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  static String _label(AppLocalizations l10n, MatchAction action) =>
      switch (action) {
        MatchAction.start => l10n.tlStart,
        MatchAction.stop => l10n.tlStop,
        MatchAction.point => l10n.tlPoint,
        MatchAction.warning => l10n.actionWarning,
        MatchAction.oneHandWarning => l10n.actionOneHand,
        MatchAction.disqualification => l10n.actionDisqualify,
        MatchAction.undo => l10n.tlUndo,
        MatchAction.finish => l10n.tlFinish,
      };
}
