import 'match_view.dart';

/// Why an action cannot happen now: the server's `TamboMatch.refuse`, then what the offline
/// queue checks on top (`notForAge`, `inReview`, `matBusy`), which the server would turn into
/// a review.
enum MatchRefusal {
  finished,
  over,
  notStarted,
  running,
  notRunning,
  nothingToUndo,
  notOver,
  notForAge,
  inReview,
  matBusy,
}

/// [target]: for an UNDO, the entry it undoes.
class TamboEntry {
  const TamboEntry({
    required this.id,
    required this.action,
    required this.at,
    this.side,
    this.target,
  });

  final String id;
  final MatchAction action;
  final Side? side;
  final DateTime at;
  final String? target;
}

class _Tally {
  var points = 0;
  var warnings = 0;
  var oneHandWarnings = 0;
}

/// State of a tambo match rebuilt from its entries in order: the same rules as the server's
/// `TamboMatch` (reglamento Yoseikan, cap. 3.1), so the device can play on without network.
class TamboMatch {
  TamboMatch._(this.length, this.pointsLimit);

  factory TamboMatch.replay({
    required Duration length,
    required int pointsLimit,
    required List<TamboEntry> entries,
  }) {
    final match = TamboMatch._(length, pointsLimit);
    final undone = {
      for (final e in entries)
        if (e.action == MatchAction.undo) e.target,
    };
    for (final e in entries) {
      if (e.action != MatchAction.undo && !undone.contains(e.id)) {
        match._apply(e);
      }
    }
    return match;
  }

  final Duration length;
  final int pointsLimit;
  final _tallies = {Side.red: _Tally(), Side.blue: _Tally()};
  final _autoPointWarnings = <String>{};
  var _elapsed = Duration.zero;
  DateTime? _runningSince;
  Side? _disqualified;
  var _started = false;
  var _finished = false;
  TamboEntry? _lastUndoable;

  void _apply(TamboEntry e) {
    switch (e.action) {
      case MatchAction.start:
        _started = true;
        _runningSince ??= e.at;
      case MatchAction.stop:
        _elapsed = elapsedAt(e.at);
        _runningSince = null;
      case MatchAction.point:
        _tallies[e.side]!.points++;
        _lastUndoable = e;
      case MatchAction.warning:
        _tallies[e.side]!.warnings++;
        _lastUndoable = e;
      case MatchAction.oneHandWarning:
        // Every second one-hand warning gives the rival a point.
        if (++_tallies[e.side]!.oneHandWarnings % 2 == 0) {
          _tallies[_rival(e.side!)]!.points++;
          _autoPointWarnings.add(e.id);
        }
        _lastUndoable = e;
      case MatchAction.disqualification:
        _disqualified = e.side;
        _lastUndoable = e;
      case MatchAction.finish:
        _finished = true;
      case MatchAction.undo:
        throw ArgumentError('UNDO entries are never applied');
    }
  }

  static Side _rival(Side side) => side == Side.red ? Side.blue : Side.red;

  Duration elapsedAt(DateTime now) {
    final since = _runningSince;
    final total = since == null ? _elapsed : _elapsed + now.difference(since);
    return total > length ? length : total;
  }

  Duration remainingAt(DateTime now) => length - elapsedAt(now);

  /// True while the clock runs; it stops by itself when the time is over.
  bool isRunning(DateTime now) =>
      _runningSince != null && remainingAt(now) > Duration.zero;

  EndReason? endReason(DateTime now) {
    if (_disqualified != null) return EndReason.disqualification;
    if (_tallies.values.any((t) => t.points >= pointsLimit)) {
      return EndReason.points;
    }
    return remainingAt(now) == Duration.zero ? EndReason.time : null;
  }

  int points(Side side) => _tallies[side]!.points;
  int warnings(Side side) => _tallies[side]!.warnings;
  int oneHandWarnings(Side side) => _tallies[side]!.oneHandWarnings;
  Side? get disqualified => _disqualified;
  bool get started => _started;
  bool get finished => _finished;
  TamboEntry? get lastUndoable => _lastUndoable;
  bool gaveAutoPoint(String oneHandWarningId) =>
      _autoPointWarnings.contains(oneHandWarningId);

  /// Why [action] cannot happen at [now], or null if it can. Checks only the match itself.
  MatchRefusal? refuse(MatchAction action, DateTime now) {
    if (_finished) return MatchRefusal.finished;
    final over = endReason(now) != null;
    return switch (action) {
      MatchAction.start =>
        over
            ? MatchRefusal.over
            : isRunning(now)
            ? MatchRefusal.running
            : null,
      MatchAction.stop => isRunning(now) ? null : MatchRefusal.notRunning,
      MatchAction.point ||
      MatchAction.warning ||
      MatchAction.oneHandWarning ||
      MatchAction.disqualification =>
        over
            ? MatchRefusal.over
            : !_started
            ? MatchRefusal.notStarted
            : null,
      MatchAction.undo =>
        _lastUndoable == null ? MatchRefusal.nothingToUndo : null,
      MatchAction.finish => over ? null : MatchRefusal.notOver,
    };
  }
}
