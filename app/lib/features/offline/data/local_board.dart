import '../../mat/data/mat_board.dart';
import '../../scoreboard/data/match_view.dart';

/// [board] (from the server, or from the cache when [MatBoard.offline]) with what the device
/// knows on top: [local] are the matches as the device shows them, [inReview] the ones waiting
/// for the club. Without network there is no recommendation (other mats are unknown): any
/// pending match of this mat can start while none is in progress here; of the team pool, only
/// the one last proposed to this mat (another mat may take the others).
/// Offline, [MatBoard.recommendedMatchId] is the one the server last proposed here.
MatBoard localBoard(
  MatBoard board, {
  required Map<String, MatchView> local,
  required Set<String> inReview,
}) {
  final matches = [
    for (final m in board.matches)
      switch (local[m.id]) {
        null => m,
        final view => m.copyWith(
          status: view.status,
          redScore: view.red.points,
          blueScore: view.blue.points,
        ),
      }.copyWith(inReview: m.inReview || inReview.contains(m.id)),
  ];
  final busy = matches.any((m) => m.status == MatchStatus.inProgress);
  final shown = [
    for (final m in matches)
      m.copyWith(
        available: board.offline
            ? m.status == MatchStatus.pending &&
                  !m.inReview &&
                  !busy &&
                  (!m.pool || m.id == board.recommendedMatchId)
            : m.available && m.status == MatchStatus.pending && !m.inReview,
      ),
  ];
  final recommended = shown
      .where((m) => m.id == board.recommendedMatchId && m.available)
      .firstOrNull;
  return MatBoard(
    matNumber: board.matNumber,
    groups: board.groups,
    matches: shown,
    recommendedMatchId: board.offline ? null : recommended?.id,
    offline: board.offline,
    teamPool: board.teamPool,
    eventId: board.eventId,
    mats: board.mats,
    syncingMats: board.syncingMats,
  );
}
