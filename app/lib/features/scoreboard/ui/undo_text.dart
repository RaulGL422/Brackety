import '../../../l10n/gen/app_localizations.dart';
import '../data/match_view.dart';
import 'corner_panel.dart';

/// What an undo of [entry] takes back, for its button and the message after it: "+1 Rojo".
String undoTarget(AppLocalizations l10n, TimelineEntry entry) {
  final corner = entry.side == null ? '' : cornerName(l10n, entry.side!);
  return switch (entry.action) {
    MatchAction.warning => l10n.whatWarning(corner),
    MatchAction.oneHandWarning => l10n.whatOneHand(corner),
    MatchAction.disqualification => l10n.whatDisqualification(corner),
    _ => l10n.whatPoint(corner),
  };
}
