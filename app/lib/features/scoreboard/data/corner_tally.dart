import 'scoring.dart';

/// What one corner has in a match: points, warnings and the actions that scored, for the
/// tiebreaks. The same as the server's `CornerTally`.
class CornerTally {
  var points = 0;
  var warnings = 0;
  var oneHandWarnings = 0;

  // Each scoring action still in force: its value and its place among all the match's
  // actions. Not the points of the rival's warnings.
  final _actions = <({int value, int order})>[];

  void score(int value, int order) {
    points += value;
    _actions.add((value: value, order: order));
  }

  // The latest action of that value goes.
  void takeBack(int value) {
    points = points > value ? points - value : 0;
    final i = _actions.lastIndexWhere((a) => a.value == value);
    if (i >= 0) _actions.removeAt(i);
  }

  void clear() {
    points = 0;
    warnings = 0;
    oneHandWarnings = 0;
    _actions.clear();
  }

  /// Positive when [red] leads, negative when [blue] does, 0 on a tie. A tie on points
  /// goes through [tiebreaks] in order; [Tiebreak.extraTime] is not decided here: the
  /// referee says who won it.
  static int compare(
    CornerTally red,
    CornerTally blue, {
    required List<Tiebreak> tiebreaks,
  }) {
    var result = red.points.compareTo(blue.points);
    for (final tiebreak in tiebreaks) {
      if (result != 0) return result;
      result = switch (tiebreak) {
        // Grappling, art. 31: a 4 beats any number of 2s, two 2s beat one 2.
        Tiebreak.bestAction => _byBestAction(red, blue),
        Tiebreak.fewerWarnings =>
          (blue.warnings + blue.oneHandWarnings).compareTo(
            red.warnings + red.oneHandWarnings,
          ),
        Tiebreak.lastToScore => red._lastOrder.compareTo(blue._lastOrder),
        Tiebreak.extraTime => 0,
      };
    }
    return result;
  }

  static int _byBestAction(CornerTally red, CornerTally blue) {
    final byBest = red._best.compareTo(blue._best);
    if (byBest != 0) return byBest;
    return red._countOf(red._best).compareTo(blue._countOf(blue._best));
  }

  int get _best =>
      _actions.fold(0, (most, a) => a.value > most ? a.value : most);

  int _countOf(int value) => _actions.where((a) => a.value == value).length;

  int get _lastOrder =>
      _actions.fold(-1, (last, a) => a.order > last ? a.order : last);
}
