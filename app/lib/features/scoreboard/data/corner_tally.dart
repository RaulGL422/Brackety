/// What one corner has in a match: points, warnings and the actions that scored, for the
/// tiebreak. The same as the server's `CornerTally`.
class CornerTally {
  var points = 0;
  var warnings = 0;
  var oneHandWarnings = 0;

  // The value of each scoring action still in force; not the points of the rival's warnings.
  final _actions = <int>[];

  void score(int value) {
    points += value;
    _actions.add(value);
  }

  void takeBack(int value) {
    points = points > value ? points - value : 0;
    _actions.remove(value);
  }

  void clear() {
    points = 0;
    warnings = 0;
    oneHandWarnings = 0;
    _actions.clear();
  }

  /// Positive when [red] leads, negative when [blue] does, 0 on a tie. With [tiebreaks]
  /// (grappling, art. 31), a tie on points goes to the action of most value, then how many
  /// of it, then fewer warnings: a 4 beats any number of 2s, two 2s beat one 2, and one 2
  /// each is a tie whatever else they scored.
  static int compare(
    CornerTally red,
    CornerTally blue, {
    required bool tiebreaks,
  }) {
    final byPoints = red.points.compareTo(blue.points);
    if (byPoints != 0 || !tiebreaks) return byPoints;
    final byBest = red._best.compareTo(blue._best);
    if (byBest != 0) return byBest;
    final byCount = red
        ._countOf(red._best)
        .compareTo(blue._countOf(blue._best));
    if (byCount != 0) return byCount;
    return (blue.warnings + blue.oneHandWarnings).compareTo(
      red.warnings + red.oneHandWarnings,
    );
  }

  int get _best => _actions.fold(0, (most, v) => v > most ? v : most);

  int _countOf(int value) => _actions.where((v) => v == value).length;
}
