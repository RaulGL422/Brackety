import '../../mat/data/mat_board.dart';
import '../../scoreboard/data/match_view.dart';
import '../../scoreboard/data/tambo_match.dart';
import 'offline_op.dart';

/// A match as the device shows it: the last view from the server with the queued actions
/// replayed on top, the way the server will apply them (`MatchWriter.append`).
class LocalMatch {
  LocalMatch._(this.view, this._state, this._lastAt);

  /// [pending]: this match's queued actions, in order; [now]: the corrected device time.
  /// [heldForReview]: a 409 said so before any view with the review came.
  factory LocalMatch.project(
    MatchView server,
    List<OfflineOp> pending,
    DateTime now, {
    bool heldForReview = false,
  }) {
    // The server's timeline already says what is undone, so its undos are not needed again.
    final entries = <TamboEntry>[
      for (final (i, e) in server.timeline.indexed)
        if (e.action != MatchAction.undo && !e.undone)
          TamboEntry(
            id: e.id ?? 'server-$i',
            action: e.action,
            side: e.side,
            at: e.at,
            delta: e.delta ?? Duration.zero,
          ),
    ];
    final timeline = [...server.timeline];
    var lastAt = server.timeline.lastOrNull?.at;
    TamboMatch replay() => TamboMatch.replay(
      length: server.length,
      pointsLimit: server.pointsLimit,
      entries: entries,
    );
    for (final op in pending) {
      final at = lastAt != null && op.at.isBefore(lastAt) ? lastAt : op.at;
      final before = replay();
      // The server would put the match in review; the device just leaves it out.
      if (before.refuse(
            op.action,
            at,
            side: op.side,
            delta: op.delta ?? Duration.zero,
          ) !=
          null) {
        continue;
      }
      entries.add(
        TamboEntry(
          id: op.opId,
          action: op.action,
          side: op.side,
          at: at,
          delta: op.delta ?? Duration.zero,
          target: op.action == MatchAction.undo
              ? before.lastUndoable!.id
              : null,
        ),
      );
      timeline.add(
        TimelineEntry(
          id: op.opId,
          opId: op.opId,
          action: op.action,
          side: op.side,
          reason: op.reason,
          delta: op.delta,
          at: at,
          clock: before.elapsedAt(at),
          automatic: false,
          undone: false,
          gaveRivalPoint: false,
        ),
      );
      lastAt = at;
      // Points or a disqualification stop the clock, as the server does.
      final after = replay();
      final end = after.endReason(at);
      if (end != null && end != EndReason.time && after.isRunning(at)) {
        entries.add(
          TamboEntry(id: 'stop-${op.opId}', action: MatchAction.stop, at: at),
        );
        timeline.add(
          TimelineEntry(
            id: 'stop-${op.opId}',
            action: MatchAction.stop,
            at: at,
            clock: after.elapsedAt(at),
            automatic: true,
            undone: false,
            gaveRivalPoint: false,
          ),
        );
      }
    }
    final state = replay();
    final undone = {
      for (final e in entries)
        if (e.target != null) e.target,
    };
    Corner corner(Side side) => server
        .corner(side)
        .withTally(
          points: state.points(side),
          warnings: state.warnings(side),
          oneHandWarnings: state.oneHandWarnings(side),
          disqualified: state.disqualified == side,
        );
    final view = pending.isEmpty && !heldForReview
        ? _serverAt(server, now)
        : MatchView(
            id: server.id,
            matId: server.matId,
            matNumber: server.matNumber,
            groupNumber: server.groupNumber,
            status: state.finished
                ? MatchStatus.finished
                : timeline.length > server.timeline.length
                ? MatchStatus.inProgress
                : server.status,
            length: server.length,
            pointsLimit: server.pointsLimit,
            remaining: state.remainingAt(now),
            running: state.isRunning(now),
            endReason: state.endReason(now),
            red: corner(Side.red),
            blue: corner(Side.blue),
            timeline: [
              for (final e in timeline)
                e.id == null
                    ? e
                    : e.withFlags(
                        undone: e.undone || undone.contains(e.id),
                        gaveRivalPoint:
                            e.gaveRivalPoint || state.gaveAutoPoint(e.id!),
                      ),
            ],
            serverTime: server.serverTime,
            review:
                server.review ??
                (heldForReview ? const MatchReview.pending() : null),
          );
    return LocalMatch._(view, state, lastAt);
  }

  // Nothing queued: the server's view is the truth, only its clock moves on since it was sent.
  static MatchView _serverAt(MatchView server, DateTime now) {
    final sent = server.serverTime;
    if (!server.running || sent == null) return server;
    final left = server.remaining - now.difference(sent);
    return server.withRemaining(left.isNegative ? Duration.zero : left);
  }

  final MatchView view;
  final TamboMatch _state;
  final DateTime? _lastAt;

  /// Why the referee cannot do [action] now, checked here before it goes into the queue.
  MatchRefusal? refuse(
    MatchAction action,
    Side? side,
    DateTime now, {
    Duration delta = Duration.zero,
  }) {
    if (view.review != null) return MatchRefusal.inReview;
    if (action == MatchAction.oneHandWarning &&
        side != null &&
        !view.corner(side).oneHandRule) {
      return MatchRefusal.notForAge;
    }
    final lastAt = _lastAt;
    return _state.refuse(
      action,
      lastAt != null && now.isBefore(lastAt) ? lastAt : now,
      side: side,
      delta: delta,
    );
  }
}
