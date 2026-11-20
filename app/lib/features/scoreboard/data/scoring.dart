/// How a sport scores, apart from the length and the limit of each match: the same as the
/// server's `MatchRules.Scoring`.
class Scoring {
  const Scoring({
    required this.warningsPerRivalPoint,
    required this.warningsToDisqualify,
    required this.superiorityGap,
    required this.pointsAfterTime,
    required this.disqualificationScores,
    required this.oneHandWarnings,
    required this.submissions,
    required this.tiebreaks,
    required this.maxPointValue,
  });

  /// Liga Yoseikan, cap. 3.1, and Raul's rules of the F1 (2026-11-13).
  static const tambo = Scoring(
    warningsPerRivalPoint: 2,
    warningsToDisqualify: 0,
    superiorityGap: 0,
    pointsAfterTime: true,
    disqualificationScores: true,
    oneHandWarnings: true,
    submissions: false,
    tiebreaks: false,
    maxPointValue: 1,
  );

  /// FELODA, November 2025: art. 29, 31, 38, 40, 41 and 44.
  static const grappling = Scoring(
    warningsPerRivalPoint: 1,
    warningsToDisqualify: 4,
    superiorityGap: 15,
    pointsAfterTime: false,
    disqualificationScores: false,
    oneHandWarnings: false,
    submissions: true,
    tiebreaks: true,
    maxPointValue: 4,
  );

  /// Every this many warnings of a fighter, the rival gets a point.
  final int warningsPerRivalPoint;

  /// The warning that disqualifies; 0: none.
  final int warningsToDisqualify;

  /// The points difference that ends the match; 0: none.
  final int superiorityGap;

  /// The last action's point still counts once the clock shows 0:00.
  final bool pointsAfterTime;

  /// A disqualification scores 0 for the disqualified and the limit for the rival.
  final bool disqualificationScores;
  final bool oneHandWarnings;
  final bool submissions;

  /// A tie on points is broken by the actions of more value, then fewer warnings, then
  /// extra time.
  final bool tiebreaks;
  final int maxPointValue;
}
