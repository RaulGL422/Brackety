import 'package:brackety/features/scoreboard/data/match_view.dart';
import 'package:brackety/features/scoreboard/data/tambo_match.dart';
import 'package:flutter_test/flutter_test.dart';

// The same cases as the server's TamboMatchTest: both must agree on every rule.
void main() {
  final t0 = DateTime.utc(2027, 3, 10, 9);
  late List<TamboEntry> entries;
  var ids = 0;

  setUp(() => entries = []);

  DateTime at(int second) => t0.add(Duration(seconds: second));

  String add(MatchAction action, Side? side, int second, [String? target]) {
    final id = 'e${ids++}';
    entries.add(
      TamboEntry(
        id: id,
        action: action,
        side: side,
        at: at(second),
        target: target,
      ),
    );
    return id;
  }

  TamboMatch replay() => TamboMatch.replay(
    length: const Duration(minutes: 2),
    pointsLimit: 15,
    entries: entries,
  );

  test('nothing scores before the first start; after a stop it does', () {
    const scoring = [
      MatchAction.point,
      MatchAction.warning,
      MatchAction.oneHandWarning,
      MatchAction.disqualification,
    ];
    for (final action in scoring) {
      expect(replay().refuse(action, at(5)), MatchRefusal.notStarted);
    }

    add(MatchAction.start, null, 0);
    add(MatchAction.stop, null, 10);

    for (final action in scoring) {
      expect(replay().refuse(action, at(20)), isNull);
    }
  });

  test('the clock only runs between start and stop', () {
    add(MatchAction.start, null, 0);
    add(MatchAction.stop, null, 30);
    add(MatchAction.start, null, 50);

    final match = replay();

    expect(match.remainingAt(at(60)), const Duration(seconds: 80));
    expect(match.isRunning(at(60)), isTrue);
    expect(match.endReason(at(60)), isNull);
    expect(match.refuse(MatchAction.start, at(60)), MatchRefusal.running);
    expect(match.refuse(MatchAction.finish, at(60)), MatchRefusal.notOver);
  });

  test('when the time is over the clock stops and only finish is left', () {
    add(MatchAction.start, null, 0);
    add(MatchAction.point, Side.red, 10);

    final match = replay();

    expect(match.remainingAt(at(500)), Duration.zero);
    expect(match.isRunning(at(500)), isFalse);
    expect(match.endReason(at(500)), EndReason.time);
    expect(match.refuse(MatchAction.start, at(500)), isNotNull);
    expect(match.refuse(MatchAction.point, at(500)), isNotNull);
    expect(match.refuse(MatchAction.finish, at(500)), isNull);
  });

  test('fifteen points end the match and undoing the last one reopens it', () {
    add(MatchAction.start, null, 0);
    for (var i = 0; i < 15; i++) {
      add(MatchAction.point, Side.blue, i + 1);
    }

    expect(replay().endReason(at(20)), EndReason.points);
    expect(replay().refuse(MatchAction.point, at(20)), isNotNull);

    add(MatchAction.undo, null, 21, entries.last.id);
    final match = replay();
    expect(match.points(Side.blue), 14);
    expect(match.endReason(at(22)), isNull);
  });

  test('every second one-hand warning gives the rival a point', () {
    add(MatchAction.start, null, 0);
    add(MatchAction.oneHandWarning, Side.red, 5);
    final second = add(MatchAction.oneHandWarning, Side.red, 10);
    add(MatchAction.oneHandWarning, Side.red, 15);

    final match = replay();
    expect(match.points(Side.red), 0);
    expect(match.warnings(Side.red), 0);
    expect(match.oneHandWarnings(Side.red), 3);
    expect(match.points(Side.blue), 1);
    expect(match.gaveAutoPoint(second), isTrue);

    add(MatchAction.undo, null, 20, entries.last.id);
    add(MatchAction.undo, null, 21, second);
    expect(replay().points(Side.blue), 0);
  });

  test('a disqualification ends the match until undone', () {
    add(MatchAction.start, null, 0);
    add(MatchAction.warning, Side.blue, 3);
    final dq = add(MatchAction.disqualification, Side.blue, 5);
    add(MatchAction.stop, null, 5);

    var match = replay();
    expect(match.endReason(at(6)), EndReason.disqualification);
    expect(match.disqualified, Side.blue);
    expect(match.lastUndoable?.id, dq);

    add(MatchAction.undo, null, 7, dq);
    match = replay();
    expect(match.endReason(at(8)), isNull);
    expect(match.isRunning(at(8)), isFalse);
    expect(match.warnings(Side.blue), 1);
  });

  test('undo walks back one action at a time', () {
    add(MatchAction.start, null, 0);
    final first = add(MatchAction.point, Side.red, 1);
    final second = add(MatchAction.point, Side.blue, 2);

    add(MatchAction.undo, null, 3, second);
    expect(replay().lastUndoable?.id, first);
    add(MatchAction.undo, null, 4, first);
    final match = replay();
    expect(match.lastUndoable, isNull);
    expect(match.refuse(MatchAction.undo, at(5)), MatchRefusal.nothingToUndo);
    expect(match.points(Side.red) + match.points(Side.blue), 0);
  });

  test('a finished match refuses everything', () {
    add(MatchAction.start, null, 0);
    add(MatchAction.disqualification, Side.red, 1);
    add(MatchAction.finish, null, 2);

    final match = replay();
    expect(match.finished, isTrue);
    for (final action in MatchAction.values) {
      expect(match.refuse(action, at(3)), MatchRefusal.finished);
    }
  });

  test('stop needs a running clock', () {
    expect(replay().refuse(MatchAction.stop, t0), MatchRefusal.notRunning);
    expect(replay().started, isFalse);
  });
}
