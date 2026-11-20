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

/// How the match's sport scores: the server's `ScoringRules`, sent with each match and kept by
/// its event, so the app holds no copy of any sport's rules.
class Scoring {
  const Scoring({
    required this.actions,
    required this.warningsPerRivalPoint,
    required this.warningsToDisqualify,
    required this.superiorityGap,
    required this.pointsAfterTime,
    required this.disqualificationScores,
    required this.oneHandWarnings,
    required this.submissions,
    required this.tiebreaks,
  });

  /// A view stored by an app from before the rules came with the match (only tambo existed).
  static const tambo = Scoring(
    actions: [ScoringAction(value: 1, label: 'Punto')],
    warningsPerRivalPoint: 2,
    warningsToDisqualify: 0,
    superiorityGap: 0,
    pointsAfterTime: true,
    disqualificationScores: true,
    oneHandWarnings: true,
    submissions: false,
    tiebreaks: false,
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
          warningsPerRivalPoint: json['warningsPerRivalPoint'] as int,
          warningsToDisqualify: json['warningsToDisqualify'] as int,
          superiorityGap: json['superiorityGap'] as int,
          pointsAfterTime: json['pointsAfterTime'] as bool,
          disqualificationScores: json['disqualificationScores'] as bool,
          oneHandWarnings: json['oneHandWarnings'] as bool,
          submissions: json['submissions'] as bool,
          tiebreaks: json['tiebreaks'] as bool,
        );

  /// The referee's buttons, each with its points.
  final List<ScoringAction> actions;

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

  /// A tie on points is broken by the best action, how many of it, fewer warnings, then
  /// extra time.
  final bool tiebreaks;

  /// Some button is worth [value] points.
  bool hasValue(int value) => actions.any((a) => a.value == value);

  Map<String, dynamic> toJson() => {
    'actions': [for (final a in actions) a.toJson()],
    'warningsPerRivalPoint': warningsPerRivalPoint,
    'warningsToDisqualify': warningsToDisqualify,
    'superiorityGap': superiorityGap,
    'pointsAfterTime': pointsAfterTime,
    'disqualificationScores': disqualificationScores,
    'oneHandWarnings': oneHandWarnings,
    'submissions': submissions,
    'tiebreaks': tiebreaks,
  };
}
