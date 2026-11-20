import 'corner_tally.dart';
import 'match_view.dart';
import 'scoring.dart';

export 'scoring.dart';

/// Why an action cannot happen now: the server's `MatchState.refuse`, then what the offline
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
  notFinished,
  noPoints,
  clockRunning,
  clockLimit,

  /// The action does not exist in this sport (a submission in tambo).
  notInThisSport,

  /// No action of the sport is worth that many points.
  invalidValue,

  /// The extra time is only for a tie that no tiebreaker settles.
  noExtraTime,

  /// Tied after every tiebreaker: the extra time comes before finishing.
  extraTimePending,
  notForAge,
  inReview,
  matBusy,

  /// A fighter has not had the least rest since their last match.
  resting,
}

/// [target]: for an UNDO, the entry it undoes. [delta]: for a CLOCK_ADJUST, the time added.
/// [value]: for a POINT or POINT_REMOVED, how many points.
class MatchEntry {
  const MatchEntry({
    required this.id,
    required this.action,
    required this.at,
    this.side,
    this.target,
    this.delta = Duration.zero,
    this.value = 1,
  });

  final String id;
  final MatchAction action;
  final Side? side;
  final DateTime at;
  final String? target;
  final Duration delta;
  final int value;
}

/// State of a match rebuilt from its entries in order: the same rules as the server's
/// `MatchState` (docs/reglamentos: tambo of the Yoseikan league, grappling of the FELODA),
/// so the device can play on without network.
class MatchState {
  MatchState._(this.length, this.pointsLimit, this.scoring);

  factory MatchState.replay({
    required Duration length,
    required int pointsLimit,
    Scoring scoring = Scoring.tambo,
    required List<MatchEntry> entries,
  }) {
    final match = MatchState._(length, pointsLimit, scoring);
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
  final Scoring scoring;
  final _tallies = {Side.red: CornerTally(), Side.blue: CornerTally()};
  final _autoPointWarnings = <String>{};
  var _elapsed = Duration.zero;
  DateTime? _runningSince;
  Side? _disqualified;
  var _disqualifiedByWarnings = false;
  Side? _submittedBy;
  Side? _extraTimeWinner;
  var _started = false;
  var _finished = false;
  MatchEntry? _lastUndoable;

  // How many points have been scored, to know who scored last.
  var _scored = 0;

  void _apply(MatchEntry e) {
    switch (e.action) {
      case MatchAction.start:
        _started = true;
        _runningSince ??= e.at;
      case MatchAction.stop:
        _elapsed = elapsedAt(e.at);
        _runningSince = null;
      case MatchAction.point:
        _tallies[e.side]!.score(e.value, ++_scored);
      case MatchAction.pointRemoved:
        _tallies[e.side]!.takeBack(e.value);
      case MatchAction.clockAdjust:
        // Only on a stopped clock; one that ran out of time stays stopped after the adjustment.
        _elapsed = _adjusted(elapsedAt(e.at), e.delta);
        _runningSince = null;
      case MatchAction.warning:
        // Tambo: every second warning gives the rival a point; grappling: every one.
        final warnings = ++_tallies[e.side]!.warnings;
        final points = scoring.warningPointsFor(warnings);
        if (points > 0) _givePointsToRival(e, points);
        if (warnings == scoring.warningsToDisqualify) {
          _disqualified = e.side;
          _disqualifiedByWarnings = true;
        }
      case MatchAction.oneHandWarning:
        if (++_tallies[e.side]!.oneHandWarnings % 2 == 0) {
          _givePointsToRival(e, 1);
        }
      case MatchAction.disqualification:
        _disqualified = e.side;
        _disqualifiedByWarnings = false;
      case MatchAction.submission:
        _submittedBy = e.side;
      case MatchAction.extraTime:
        _extraTimeWinner = e.side;
      case MatchAction.finish:
        _finished = true;
      case MatchAction.cancel:
        _cancel();
      case MatchAction.reopen:
        _finished = false;
      case MatchAction.undo:
        throw ArgumentError('UNDO entries are never applied');
    }
    if (e.action.undoable) _lastUndoable = e;
  }

  // As if it had never started: nothing before it can be undone either.
  void _cancel() {
    for (final t in _tallies.values) {
      t.clear();
    }
    _autoPointWarnings.clear();
    _elapsed = Duration.zero;
    _runningSince = null;
    _disqualified = null;
    _disqualifiedByWarnings = false;
    _submittedBy = null;
    _extraTimeWinner = null;
    _started = false;
    _scored = 0;
    _lastUndoable = null;
  }

  static Side _rival(Side side) => side == Side.red ? Side.blue : Side.red;

  // Adding time takes it off the elapsed time, never below 0 nor beyond the match length.
  Duration _adjusted(Duration elapsedNow, Duration delta) {
    final result = elapsedNow - delta;
    if (result.isNegative) return Duration.zero;
    return result > length ? length : result;
  }

  // An adjustment must change the clock and never leave it at 0: the time runs out only by running.
  bool _cannotAdjust(DateTime now, Duration delta) {
    final result = _adjusted(elapsedAt(now), delta);
    return result == elapsedAt(now) || result == length;
  }

  Duration elapsedAt(DateTime now) {
    final since = _runningSince;
    final total = since == null ? _elapsed : _elapsed + now.difference(since);
    return total > length ? length : total;
  }

  Duration remainingAt(DateTime now) => length - elapsedAt(now);

  /// True while the clock runs; it stops by itself when the time is over.
  bool isRunning(DateTime now) =>
      _runningSince != null && remainingAt(now) > Duration.zero;

  void _givePointsToRival(MatchEntry warning, int points) {
    _tallies[_rival(warning.side!)]!.points += points;
    _autoPointWarnings.add(warning.id);
  }

  /// [pointsLimit] 0: no limit (team matches, grappling).
  bool get hasLimit => pointsLimit > 0;

  EndReason? endReason(DateTime now) {
    if (_disqualified != null) {
      return _disqualifiedByWarnings
          ? EndReason.warnings
          : EndReason.disqualification;
    }
    if (_submittedBy != null) return EndReason.submission;
    if (_extraTimeWinner != null) return EndReason.extraTime;
    if (hasLimit && _tallies.values.any((t) => t.points >= pointsLimit)) {
      return EndReason.points;
    }
    final gap = scoring.superiorityGap;
    if (gap > 0 &&
        (_tallies[Side.red]!.points - _tallies[Side.blue]!.points).abs() >=
            gap) {
      return EndReason.superiority;
    }
    return remainingAt(now) == Duration.zero ? EndReason.time : null;
  }

  /// Who won, once the match is over; null while it goes on, on a draw (tambo) or while a
  /// tie waits for the extra time (grappling, art. 31).
  Side? winner(DateTime now) => switch (endReason(now)) {
    null => null,
    EndReason.disqualification || EndReason.warnings => _rival(_disqualified!),
    EndReason.submission => _submittedBy,
    EndReason.extraTime => _extraTimeWinner,
    EndReason.points || EndReason.superiority || EndReason.time => _onPoints(),
  };

  // More points; on a tie, the sport's tiebreakers (CornerTally).
  Side? _onPoints() {
    final lead = CornerTally.compare(
      _tallies[Side.red]!,
      _tallies[Side.blue]!,
      tiebreaks: scoring.tiebreaks,
    );
    return lead == 0
        ? null
        : lead > 0
        ? Side.red
        : Side.blue;
  }

  /// The time ended on a tie that no tiebreaker settles: only the extra time decides
  /// (grappling, art. 32).
  bool needsExtraTime(DateTime now) =>
      scoring.hasExtraTime &&
      endReason(now) == EndReason.time &&
      winner(now) == null;

  /// What a disqualification gives the rival when there is no points limit, at least.
  static const disqualificationPoints = 15;

  /// With [Scoring.disqualificationScores], a disqualification scores 0 for the disqualified
  /// fighter and the points limit for the rival, or with no limit the rival's points but at
  /// least [disqualificationPoints]; the tally stays, so undoing it gives the points back.
  int points(Side side) {
    final disqualified = _disqualified;
    if (disqualified == null || !scoring.disqualificationScores) {
      return _tallies[side]!.points;
    }
    if (disqualified == side) return 0;
    if (hasLimit) return pointsLimit;
    final own = _tallies[side]!.points;
    return own > disqualificationPoints ? own : disqualificationPoints;
  }

  int warnings(Side side) => _tallies[side]!.warnings;
  int oneHandWarnings(Side side) => _tallies[side]!.oneHandWarnings;
  Side? get disqualified => _disqualified;
  bool get started => _started;
  bool get finished => _finished;
  MatchEntry? get lastUndoable => _lastUndoable;

  /// True for a warning (of either kind) that gave the rival a point.
  bool gaveAutoPoint(String warningId) =>
      _autoPointWarnings.contains(warningId);

  /// Why [action] cannot happen at [now], or null if it can. Checks only the match itself.
  /// [side]: for a point removed; [delta]: for a clock adjustment; [value]: for points.
  MatchRefusal? refuse(
    MatchAction action,
    DateTime now, {
    Side? side,
    Duration delta = Duration.zero,
    int value = 1,
  }) {
    if (_finished) {
      return action == MatchAction.reopen ? null : MatchRefusal.finished;
    }
    final notInThisSport = switch (action) {
      MatchAction.oneHandWarning => !scoring.oneHandWarnings,
      MatchAction.submission => scoring.finishes.isEmpty,
      MatchAction.extraTime => !scoring.hasExtraTime,
      _ => false,
    };
    if (notInThisSport) return MatchRefusal.notInThisSport;
    if ((action == MatchAction.point || action == MatchAction.pointRemoved) &&
        !scoring.hasValue(value)) {
      return MatchRefusal.invalidValue;
    }
    final end = endReason(now);
    final over = end != null;
    // The time ended the match, but the last action's point may still come (tambo, F1-3).
    final overButTime = end != null && end != EndReason.time;
    return switch (action) {
      MatchAction.start =>
        over
            ? MatchRefusal.over
            : isRunning(now)
            ? MatchRefusal.running
            : null,
      MatchAction.stop => isRunning(now) ? null : MatchRefusal.notRunning,
      MatchAction.point =>
        (scoring.pointsAfterTime ? overButTime : over)
            ? MatchRefusal.over
            : !_started
            ? MatchRefusal.notStarted
            : null,
      MatchAction.warning ||
      MatchAction.oneHandWarning ||
      MatchAction.disqualification ||
      MatchAction.submission =>
        over
            ? MatchRefusal.over
            : !_started
            ? MatchRefusal.notStarted
            : null,
      // A correction: also once the time or the points ended the match, which it may reopen.
      MatchAction.pointRemoved =>
        !_started
            ? MatchRefusal.notStarted
            : _disqualified != null ||
                  _submittedBy != null ||
                  _extraTimeWinner != null
            ? MatchRefusal.over
            : side != null && _tallies[side]!.points < value
            ? MatchRefusal.noPoints
            : null,
      MatchAction.clockAdjust =>
        isRunning(now)
            ? MatchRefusal.clockRunning
            : overButTime
            ? MatchRefusal.over
            : _cannotAdjust(now, delta)
            ? MatchRefusal.clockLimit
            : null,
      MatchAction.extraTime =>
        needsExtraTime(now) ? null : MatchRefusal.noExtraTime,
      MatchAction.undo =>
        _lastUndoable == null ? MatchRefusal.nothingToUndo : null,
      MatchAction.finish =>
        !over
            ? MatchRefusal.notOver
            : needsExtraTime(now)
            ? MatchRefusal.extraTimePending
            : null,
      MatchAction.cancel => _started ? null : MatchRefusal.notStarted,
      MatchAction.reopen => MatchRefusal.notFinished,
    };
  }
}
