import 'package:brackety/features/scoreboard/data/match_view.dart';
import 'package:brackety/features/scoreboard/data/scoring.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/match_fakes.dart';

/// The match brings its sport's rules from the server (docs/producto/grappling.md, G2a).
void main() {
  const grappling = Scoring(
    actions: [
      ScoringAction(value: 1, label: 'Salida o ataque'),
      ScoringAction(value: 2, label: 'Derribo, inversión o derribo rápido'),
      ScoringAction(value: 3, label: 'Montada lateral o derribo de amplitud'),
      ScoringAction(value: 4, label: 'Montada o espalda'),
    ],
    warningsPerRivalPoint: 1,
    warningsToDisqualify: 4,
    superiorityGap: 15,
    pointsAfterTime: false,
    disqualificationScores: false,
    oneHandWarnings: false,
    submissions: true,
    tiebreaks: true,
  );

  test('a stored view keeps its rules and buttons', () {
    final json = matchView().toJson()..['scoring'] = grappling.toJson();

    final view = MatchView.fromJson(MatchView.fromJson(json).toJson());

    expect(view.scoring.actions.map((a) => a.value), [1, 2, 3, 4]);
    expect(view.scoring.actions.last.label, 'Montada o espalda');
    expect(view.scoring.warningsToDisqualify, 4);
    expect(view.scoring.hasValue(3), isTrue);
    expect(view.scoring.hasValue(5), isFalse);
  });

  // A view cached by an app that talked to an older server: only tambo existed then.
  test('a view without rules is tambo', () {
    final json = matchView().toJson()..remove('scoring');

    final view = MatchView.fromJson(json);

    expect(view.scoring.actions.single.value, 1);
    expect(view.scoring.warningsPerRivalPoint, 2);
    expect(view.scoring.submissions, isFalse);
  });
}
