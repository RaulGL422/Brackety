import 'package:brackety/features/offline/data/offline_op.dart';
import 'package:brackety/features/offline/data/offline_ops_csv.dart';
import 'package:brackety/features/scoreboard/data/match_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the rescue file keeps every column, the clock adjustment too', () {
    final at = DateTime.utc(2027, 3, 10, 9);
    final csv = offlineOpsCsv([
      OfflineOp(
        opId: 'op1',
        matchId: 'm1',
        action: MatchAction.warning,
        side: Side.blue,
        reason: 'Agarre; sin soltar',
        at: at,
        knownEvents: 2,
        account: 'a1',
      ),
      OfflineOp(
        opId: 'op2',
        matchId: 'm1',
        action: MatchAction.clockAdjust,
        delta: const Duration(seconds: -10),
        at: at,
        knownEvents: 3,
        account: 'a1',
      ),
    ]);

    expect(csv.split('\r\n'), [
      '﻿brackety-offline-ops;2',
      'opId;matchId;type;side;reason;at;knownEvents;actor;deltaMs',
      'op1;m1;WARNING;BLUE;"Agarre; sin soltar";2027-03-10T09:00:00.000Z;2;a1;',
      'op2;m1;CLOCK_ADJUST;;;2027-03-10T09:00:00.000Z;3;a1;-10000',
      '',
    ]);
  });
}
