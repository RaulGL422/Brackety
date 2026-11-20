import '../../../l10n/gen/app_localizations.dart';
import '../data/match_view.dart';
import 'corner_panel.dart';

/// What an undo of [entry] takes back, for its button and the message after it: "+2 Rojo".
String undoTarget(AppLocalizations l10n, TimelineEntry entry) {
  final corner = entry.side == null ? '' : cornerName(l10n, entry.side!);
  return switch (entry.action) {
    MatchAction.warning => l10n.whatWarning(corner),
    MatchAction.oneHandWarning => l10n.whatOneHand(corner),
    MatchAction.disqualification => l10n.whatDisqualification(corner),
    MatchAction.pointRemoved => l10n.whatPointRemoved(entry.points, corner),
    MatchAction.clockAdjust => l10n.whatClockAdjust(
      signedSeconds(entry.delta ?? Duration.zero),
    ),
    MatchAction.submission => l10n.whatFinish(
      entry.reason ?? l10n.tlSubmission,
      corner,
    ),
    MatchAction.extraTime => l10n.whatFinish(l10n.tlExtraTime, corner),
    _ => l10n.whatPoint(entry.points, corner),
  };
}

/// "+10" or "−1": the seconds a clock adjustment adds or takes.
String signedSeconds(Duration delta) =>
    '${delta.isNegative ? '−' : '+'}${delta.inSeconds.abs()}';

/// Match clock as "m:ss".
String clockText(Duration d) =>
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
