import 'dart:async';

import 'package:brackety/features/mat/data/mat_board.dart';
import 'package:brackety/features/offline/data/local_match.dart';
import 'package:brackety/features/offline/data/offline_op.dart';
import 'package:brackety/features/scoreboard/data/match_view.dart';
import 'package:brackety/features/scoreboard/data/scoreboard_repository.dart';
import 'package:brackety/features/scoreboard/state/bell.dart';
import 'package:dio/dio.dart';

class FakeBell implements Bell {
  var rings = 0;

  @override
  void ring() => rings++;
}

Corner corner(String name, {int points = 0, bool oneHandRule = false}) =>
    Corner(
      participantId: name,
      name: name,
      ghost: false,
      oneHandRule: oneHandRule,
      points: points,
      warnings: 0,
      oneHandWarnings: 0,
      disqualified: false,
    );

/// A team corner: [number] is "Team N", with three members.
Corner teamCorner(int number, List<String> members, {bool ghost = false}) =>
    Corner(
      participantId: null,
      name: members.join(', '),
      ghost: ghost,
      oneHandRule: false,
      points: 0,
      warnings: 0,
      oneHandWarnings: 0,
      disqualified: false,
      teamNumber: number,
      members: members,
    );

MatchView matchView({
  MatchStatus status = MatchStatus.pending,
  bool running = false,
  Duration remaining = const Duration(minutes: 2),
  EndReason? endReason,
  int redPoints = 0,
  bool canUndo = false,
  Corner? red,
  Corner? blue,
  MatchReview? review,
  bool? started,
}) => MatchView(
  id: 'm1',
  matId: 'mat1',
  matNumber: 1,
  groupNumber: 3,
  status: status,
  length: const Duration(minutes: 2),
  pointsLimit: 15,
  remaining: remaining,
  running: running,
  endReason: endReason,
  review: review,
  red: red ?? corner('Ana Prueba', points: redPoints, oneHandRule: true),
  blue: blue ?? corner('Bea Prueba'),
  timeline: [
    // Started unless still pending: nothing scores before the first START.
    if (started ?? status != MatchStatus.pending)
      TimelineEntry(
        action: MatchAction.start,
        at: DateTime(2027, 3, 10, 10),
        clock: Duration.zero,
        automatic: false,
        undone: false,
        gaveRivalPoint: false,
      ),
    if (canUndo)
      TimelineEntry(
        action: MatchAction.point,
        side: Side.red,
        at: DateTime(2027, 3, 10, 10),
        clock: const Duration(seconds: 5),
        automatic: false,
        undone: false,
        gaveRivalPoint: false,
      ),
  ],
);

/// The server for the referee's queue: answers each action with [next] (or, without one, the
/// current view with the action applied by the device's own rules) and records what was sent.
class FakeScoreboardRepository implements ScoreboardRepository {
  FakeScoreboardRepository(this.current);

  MatchView current;
  MatchView? next;

  /// When set, the next action is refused with this reason (a 4xx that is not a review).
  String? refusal;

  final sent = <(MatchAction, Side?, String?)>[];
  final knownSent = <int>[];

  /// Each answer waits for this, when set: the test decides when the server answers.
  Completer<void>? hold;

  @override
  Future<MatchView> load(String matchId) async => current;

  @override
  Future<MatchView> sendOp(OfflineOp op) async {
    sent.add((op.action, op.side, op.reason));
    knownSent.add(op.knownEvents);
    await hold?.future;
    final refused = refusal;
    if (refused != null) {
      refusal = null;
      throw DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 400,
          data: {'detail': refused},
        ),
      );
    }
    current = next ?? LocalMatch.project(current, [op], op.at).view;
    next = null;
    return current;
  }

  @override
  Future<OfflineImportResult> importOps(String eventId, List<int> csv) =>
      throw UnimplementedError();

  @override
  Future<ReviewOutcome> review(String matchId, ReviewDecision decision) =>
      throw UnimplementedError();
}
