import 'package:brackety/features/mat/data/mat_board.dart';
import 'package:brackety/features/offline/data/local_board.dart';
import 'package:brackety/features/offline/data/local_match.dart';
import 'package:brackety/features/offline/data/offline_op.dart';
import 'package:brackety/features/scoreboard/data/match_view.dart';
import 'package:brackety/features/scoreboard/data/tambo_match.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/offline_fakes.dart';

void main() {
  var ids = 0;

  OfflineOp op(MatchAction action, int second, {Side? side}) => OfflineOp(
    opId: 'op${ids++}',
    matchId: 'm1',
    action: action,
    side: side,
    reason: side == null || action == MatchAction.point ? null : 'motivo',
    at: t0.add(Duration(seconds: second)),
    knownEvents: 0,
  );

  DateTime at(int second) => t0.add(Duration(seconds: second));

  group('a match with queued actions', () {
    test('replays them on the server view with the device clock', () {
      final local = LocalMatch.project(serverMatch('m1'), [
        op(MatchAction.start, 0),
        op(MatchAction.point, 10, side: Side.red),
      ], at(20));

      final view = local.view;
      expect(view.status, MatchStatus.inProgress);
      expect(view.running, isTrue);
      expect(view.remaining, const Duration(seconds: 100));
      expect(view.red.points, 1);
      expect(view.timeline.map((e) => e.clock), [
        Duration.zero,
        const Duration(seconds: 10),
      ]);
    });

    test(
      'the limit stops the clock by itself and an undo leaves it stopped',
      () {
        final server = LocalMatch.project(serverMatch('m1'), [
          op(MatchAction.start, 0),
          for (var i = 0; i < 14; i++)
            op(MatchAction.point, i + 1, side: Side.blue),
        ], at(20)).view;

        final view = LocalMatch.project(server, [
          op(MatchAction.point, 30, side: Side.blue),
          op(MatchAction.undo, 31),
        ], at(40)).view;

        expect(view.blue.points, 14);
        expect(view.running, isFalse);
        expect(view.endReason, isNull);
        expect(view.remaining, const Duration(seconds: 90));
        final stop = view.timeline.singleWhere((e) => e.automatic);
        expect(stop.action, MatchAction.stop);
        // The automatic stop is not one the device counts in knownEvents.
        expect(view.knownEvents, view.timeline.length - 1);
      },
    );

    test('an undo in the queue undoes the server last point', () {
      final server = LocalMatch.project(serverMatch('m1'), [
        op(MatchAction.start, 0),
        op(MatchAction.point, 5, side: Side.red),
      ], at(6)).view;

      final view = LocalMatch.project(server, [
        op(MatchAction.undo, 8),
      ], at(9)).view;

      expect(view.red.points, 0);
      expect(view.timeline[1].undone, isTrue);
    });

    test('an action dated before the last one counts from that one', () {
      final server = LocalMatch.project(serverMatch('m1'), [
        op(MatchAction.start, 30),
      ], at(31)).view;

      final view = LocalMatch.project(server, [
        op(MatchAction.stop, 10),
      ], at(40)).view;

      expect(view.timeline.last.at, at(30));
      expect(view.remaining, const Duration(minutes: 2));
    });

    test('what the rules refuse is left out and refused before queuing', () {
      final local = LocalMatch.project(serverMatch('m1'), [
        op(MatchAction.stop, 0),
        op(MatchAction.start, 1),
      ], at(2));

      expect(local.view.timeline, hasLength(1));
      expect(
        local.refuse(MatchAction.start, null, at(3)),
        MatchRefusal.running,
      );
      expect(
        local.refuse(MatchAction.oneHandWarning, Side.blue, at(3)),
        MatchRefusal.notForAge,
      );
      expect(local.refuse(MatchAction.oneHandWarning, Side.red, at(3)), isNull);
    });

    test('a 409 holds it for review before the server view says so', () {
      final local = LocalMatch.project(
        serverMatch('m1'),
        const [],
        at(1),
        heldForReview: true,
      );

      expect(local.view.review, isNotNull);
      expect(
        local.refuse(MatchAction.start, null, at(2)),
        MatchRefusal.inReview,
      );
    });
  });

  group('the mat board on the device', () {
    Fighter fighter(String name) =>
        Fighter(participantId: name, name: name, ghost: false);

    BoardMatch match(String id, MatchStatus status, {bool available = true}) =>
        BoardMatch(
          id: id,
          groupId: 'g1',
          groupNumber: 1,
          red: fighter('Ana'),
          blue: fighter(id),
          status: status,
          redScore: 0,
          blueScore: 0,
          available: available,
        );

    MatBoard board({bool offline = false}) => MatBoard(
      matNumber: 1,
      groups: const [],
      matches: [
        match('m1', MatchStatus.pending),
        match('m2', MatchStatus.pending, available: false),
        match('m3', MatchStatus.pending),
      ],
      recommendedMatchId: 'm1',
      offline: offline,
    );

    test('offline: no recommendation and any pending match can start', () {
      final shown = localBoard(
        board(offline: true),
        local: const {},
        inReview: {'m3'},
      );

      expect(shown.recommendedMatchId, isNull);
      expect(shown.matches.map((m) => m.available), [true, true, false]);
      expect(shown.matches[2].inReview, isTrue);
    });

    test('a match started on the device takes the mat', () {
      final started = LocalMatch.project(serverMatch('m1'), [
        op(MatchAction.start, 0),
      ], at(1)).view;

      final shown = localBoard(
        board(offline: true),
        local: {'m1': started},
        inReview: const {},
      );

      expect(shown.matches[0].status, MatchStatus.inProgress);
      expect(shown.matches.map((m) => m.available), [false, false, false]);
    });

    test('online it keeps the server recommendation and availability', () {
      final shown = localBoard(board(), local: const {}, inReview: const {});

      expect(shown.recommendedMatchId, 'm1');
      expect(shown.matches.map((m) => m.available), [true, false, true]);
    });
  });
}
