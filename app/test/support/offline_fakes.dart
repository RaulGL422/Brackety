import 'package:brackety/features/mat/data/mat_board.dart';
import 'package:brackety/features/offline/data/local_match.dart';
import 'package:brackety/features/offline/data/offline_op.dart';
import 'package:brackety/features/offline/data/offline_store.dart';
import 'package:brackety/features/offline/state/offline_sync.dart';
import 'package:brackety/features/scoreboard/data/match_view.dart';
import 'package:brackety/features/scoreboard/data/scoreboard_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/misc.dart';

import 'fakes.dart';
import 'match_fakes.dart';

final t0 = DateTime.utc(2027, 3, 10, 9);

/// The documents in memory, as the device folder would keep them.
class MemoryOfflineStore implements OfflineStore {
  final docs = <String, Object?>{};

  /// The name of every document written, in order.
  final written = <String>[];

  @override
  Future<Object?> read(String name) async => docs[name];

  @override
  Future<void> write(String name, Object? json) async {
    written.add(name);
    docs[name] = json;
  }

  @override
  Future<void> clear({Set<String> keep = const {}}) async =>
      docs.removeWhere((name, _) => !keep.contains(name));
}

/// A device clock the test moves by hand.
class TestClock {
  TestClock([DateTime? start]) : now = start ?? t0;

  DateTime now;

  void advance(Duration by) => now = now.add(by);
}

/// Android overrides: queue on, [store] and [clock] instead of the device, signed in.
List<Override> offlineOverrides({
  required MemoryOfflineStore store,
  required TestClock clock,
  required ScoreboardRepository repository,
  FakeAuthApi? auth,
}) => [
  ...sessionOverrides(auth ?? FakeAuthApi(signedIn: true)),
  offlineEnabledProvider.overrideWithValue(true),
  offlineStoreProvider.overrideWithValue(store),
  deviceClockProvider.overrideWithValue(() => clock.now),
  scoreboardRepositoryProvider.overrideWithValue(repository),
];

/// [view] as the server computes it at [at], with [review] if given.
MatchView stamped(MatchView view, DateTime at, {MatchReview? review}) =>
    MatchView(
      id: view.id,
      matId: view.matId,
      matNumber: view.matNumber,
      groupNumber: view.groupNumber,
      status: view.status,
      length: view.length,
      pointsLimit: view.pointsLimit,
      remaining: view.remaining,
      running: view.running,
      endReason: view.endReason,
      red: view.red,
      blue: view.blue,
      timeline: view.timeline,
      serverTime: at,
      review: review ?? view.review,
    );

/// A pending match [id] on mat `mat1`, as the server sends it.
MatchView serverMatch(String id, {DateTime? at}) {
  final base = matchView();
  return stamped(
    MatchView(
      id: id,
      matId: base.matId,
      matNumber: base.matNumber,
      groupNumber: base.groupNumber,
      status: MatchStatus.pending,
      length: base.length,
      pointsLimit: base.pointsLimit,
      remaining: base.remaining,
      running: false,
      red: base.red,
      blue: base.blue,
      timeline: const [],
    ),
    at ?? t0,
  );
}

/// The server's scoreboard without a server: it applies each queued action once (by `opId`)
/// with the same rules, and can be down or answer an op with an error.
class FakeMatchServer implements ScoreboardRepository {
  FakeMatchServer(Iterable<MatchView> views, this.clock)
    : views = {for (final v in views) v.id: v};

  final Map<String, MatchView> views;
  final TestClock clock;

  /// No answer at all, as without network.
  bool down = false;

  /// The next op gets this instead of being applied.
  DioException? nextOpError;

  /// The next op is applied but its answer never arrives.
  var loseNextAnswer = false;

  /// Every op that reached the server, retries included.
  final received = <OfflineOp>[];
  final _applied = <String>{};
  final _rejected = <String, String>{};
  final reviews = <(String, ReviewDecision)>[];

  @override
  Future<MatchView> load(String matchId) async {
    if (down) throw networkError();
    return stamped(views[matchId]!, clock.now);
  }

  @override
  Future<MatchView> sendOp(OfflineOp op) async {
    if (down) throw networkError();
    received.add(op);
    final error = nextOpError;
    if (error != null) {
      nextOpError = null;
      throw error;
    }
    if (_rejected[op.opId] case final code?) {
      throw httpError(409, body: {'code': code});
    }
    if (!_applied.contains(op.opId)) {
      final current = views[op.matchId]!;
      if (current.review != null || op.knownEvents != current.knownEvents) {
        final code = current.review != null
            ? 'MATCH_IN_REVIEW'
            : 'MATCH_CONFLICT';
        _rejected[op.opId] = code;
        views[op.matchId] = stamped(
          current,
          clock.now,
          review: MatchReview(
            reason: current.review?.reason ?? ReviewReason.knownEvents,
            ops: [
              ...?current.review?.ops,
              ReviewOp(
                opId: op.opId,
                action: op.action,
                side: op.side,
                reason: op.reason,
                actor: 'arbitro1',
                at: op.at,
                receivedAt: clock.now,
                cause: code == 'MATCH_CONFLICT' ? 'KNOWN_EVENTS' : 'IN_REVIEW',
              ),
            ],
          ),
        );
        throw httpError(409, body: {'code': code});
      }
      _applied.add(op.opId);
      views[op.matchId] = LocalMatch.project(current, [op], clock.now).view;
    }
    if (loseNextAnswer) {
      loseNextAnswer = false;
      throw networkError();
    }
    return stamped(views[op.matchId]!, clock.now);
  }

  /// Another device (or the web) wrote [action] in [matchId].
  void writeElsewhere(String matchId, MatchAction action) {
    views[matchId] = LocalMatch.project(views[matchId]!, [
      OfflineOp(
        opId: 'elsewhere-${views[matchId]!.timeline.length}',
        matchId: matchId,
        action: action,
        at: clock.now,
        knownEvents: views[matchId]!.knownEvents,
      ),
    ], clock.now).view;
  }

  /// The club decided: the match leaves the review.
  void resolveReview(String matchId) {
    final view = views[matchId]!;
    views[matchId] = MatchView(
      id: view.id,
      matId: view.matId,
      matNumber: view.matNumber,
      groupNumber: view.groupNumber,
      status: view.status,
      length: view.length,
      pointsLimit: view.pointsLimit,
      remaining: view.remaining,
      running: view.running,
      endReason: view.endReason,
      red: view.red,
      blue: view.blue,
      timeline: view.timeline,
      serverTime: clock.now,
    );
  }

  @override
  Future<MatchView> send(
    String matchId,
    MatchAction action, {
    Side? side,
    String? reason,
    Duration? delta,
    required int knownEvents,
  }) => throw UnimplementedError('Android sends through the queue');

  @override
  Future<ReviewOutcome> review(String matchId, ReviewDecision decision) async {
    reviews.add((matchId, decision));
    resolveReview(matchId);
    return ReviewOutcome(
      match: stamped(views[matchId]!, clock.now),
      applied: decision == ReviewDecision.apply ? 2 : 0,
      skipped: decision == ReviewDecision.apply ? 1 : 0,
    );
  }
}
