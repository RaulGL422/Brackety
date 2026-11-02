import '../../../l10n/gen/app_localizations.dart';
import '../data/mat_board.dart';

extension FighterText on FighterInfo {
  /// "Equipo N" for a team, so the referee calls it by number; the name for a participant.
  String title(AppLocalizations l10n) =>
      teamNumber == null ? name : l10n.teamName(teamNumber!);

  /// [title] plus the ghost mark.
  String label(AppLocalizations l10n) =>
      ghost ? '${title(l10n)} · ${l10n.ghostBadge}' : title(l10n);

  /// The team's participants, or null for a participant.
  String? get membersLine => teamNumber == null ? null : members.join(', ');
}
