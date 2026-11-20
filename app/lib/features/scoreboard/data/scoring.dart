/// A scoring button: what the referee saw and the points it gives.
class ScoringAction {
  const ScoringAction({required this.value, required this.label});

  factory ScoringAction.fromJson(Map<String, dynamic> json) => ScoringAction(
    value: json['value'] as int,
    label: json['label'] as String,
  );

  final int value;
  final String label;

  Map<String, dynamic> toJson() => {'value': value, 'label': label};
}

/// A way to break a tie on points, checked in the order the rules list them. The same as
/// the server's `ScoringRules.Tiebreak`.
enum Tiebreak {
  /// The action of most value, then how many of it (grappling, art. 31).
  bestAction('BEST_ACTION'),
  fewerWarnings('FEWER_WARNINGS'),

  /// Whoever scored the last action still in force.
  lastToScore('LAST_TO_SCORE'),

  /// Still tied: an extra time decides, and the referee says who won it.
  extraTime('EXTRA_TIME');

  const Tiebreak(this.wire);

  final String wire;

  static Tiebreak fromWire(String wire) =>
      values.firstWhere((t) => t.wire == wire);
}

/// How the match's sport scores: the server's `ScoringRules`, sent with each match and kept by
/// its event, so the app holds no copy of any sport's rules.
class Scoring {
  const Scoring({
    required this.actions,
    required this.warningPoints,
    required this.warningsToDisqualify,
    required this.superiorityGap,
    required this.pointsAfterTime,
    required this.disqualificationScores,
    required this.oneHandWarnings,
    required this.finishes,
    required this.tiebreaks,
  });

  /// A view stored by an app from before the rules came with the match (only tambo existed).
  static const tambo = Scoring(
    actions: [ScoringAction(value: 1, label: 'Punto')],
    warningPoints: [0, 1],
    warningsToDisqualify: 0,
    superiorityGap: 0,
    pointsAfterTime: true,
    disqualificationScores: true,
    oneHandWarnings: true,
    finishes: [],
    tiebreaks: [],
  );

  /// Null: a view from an older server, which only scored tambo.
  static Scoring fromJson(Map<String, dynamic>? json) => json == null
      ? tambo
      : Scoring(
          actions: [
            for (final a
                in (json['actions'] as List).cast<Map<String, dynamic>>())
              ScoringAction.fromJson(a),
          ],
          warningPoints: (json['warningPoints'] as List).cast<int>(),
          warningsToDisqualify: json['warningsToDisqualify'] as int,
          superiorityGap: json['superiorityGap'] as int,
          pointsAfterTime: json['pointsAfterTime'] as bool,
          disqualificationScores: json['disqualificationScores'] as bool,
          oneHandWarnings: json['oneHandWarnings'] as bool,
          finishes: (json['finishes'] as List).cast<String>(),
          tiebreaks: [
            for (final t in (json['tiebreaks'] as List).cast<String>())
              Tiebreak.fromWire(t),
          ],
        );

  /// The referee's buttons, each with its points.
  final List<ScoringAction> actions;

  /// What the rival gets for each warning of a fighter, in order, starting over when the
  /// list ends: tambo [0, 1] (every second one), grappling [1] (every one).
  final List<int> warningPoints;

  /// The warning that disqualifies; 0: none.
  final int warningsToDisqualify;

  /// The points difference that ends the match; 0: none.
  final int superiorityGap;

  /// The last action's point still counts once the clock shows 0:00.
  final bool pointsAfterTime;

  /// A disqualification scores 0 for the disqualified and the limit for the rival.
  final bool disqualificationScores;
  final bool oneHandWarnings;

  /// The actions that win the match at once (grappling: a submission), by name.
  final List<String> finishes;

  /// What breaks a tie on points, in order; empty: the tie stands (tambo).
  final List<Tiebreak> tiebreaks;

  /// Some button is worth [value] points.
  bool hasValue(int value) => actions.any((a) => a.value == value);

  /// What the rival gets for a fighter's [n]th warning (1: the first).
  int warningPointsFor(int n) => warningPoints[(n - 1) % warningPoints.length];

  bool get hasExtraTime => tiebreaks.contains(Tiebreak.extraTime);

  Map<String, dynamic> toJson() => {
    'actions': [for (final a in actions) a.toJson()],
    'warningPoints': warningPoints,
    'warningsToDisqualify': warningsToDisqualify,
    'superiorityGap': superiorityGap,
    'pointsAfterTime': pointsAfterTime,
    'disqualificationScores': disqualificationScores,
    'oneHandWarnings': oneHandWarnings,
    'finishes': finishes,
    'tiebreaks': [for (final t in tiebreaks) t.wire],
  };
}
