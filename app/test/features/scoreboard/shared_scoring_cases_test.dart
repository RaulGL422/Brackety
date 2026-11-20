import 'dart:convert';
import 'dart:io';

import 'package:brackety/features/scoreboard/data/match_view.dart';
import 'package:brackety/features/scoreboard/data/match_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// The scoring cases shared with the server (spec/scoring/tambo.json): both MatchState must
/// agree on every one.
void main() {
  final doc = jsonDecode(
    File('../spec/scoring/tambo.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final defaults = doc['rules'] as Map<String, dynamic>;
  final t0 = DateTime.utc(2027, 3, 10, 9);

  Duration duration(Object? seconds) =>
      Duration(milliseconds: ((seconds! as num) * 1000).round());
  DateTime at(Object? seconds) => t0.add(duration(seconds));
  Side? side(Object? value) => sideFromJson(value);

  for (final testCase in (doc['cases'] as List).cast<Map<String, dynamic>>()) {
    test(testCase['name'] as String, () {
      final rules = {
        ...defaults,
        ...?testCase['rules'] as Map<String, dynamic>?,
      };
      final match = MatchState.replay(
        length: duration(rules['length']),
        pointsLimit: rules['pointsLimit'] as int,
        entries: [
          for (final e
              in (testCase['entries'] as List).cast<Map<String, dynamic>>())
            MatchEntry(
              id: e['id'] as String,
              action: MatchAction.fromWire(e['action'] as String),
              at: at(e['at']),
              side: side(e['side']),
              target: e['target'] as String?,
              delta: e.containsKey('delta')
                  ? duration(e['delta'])
                  : Duration.zero,
            ),
        ],
      );
      final now = at(testCase['at']);
      final expect_ = testCase['expect'] as Map<String, dynamic>;

      for (final s in Side.values) {
        final corner = expect_[s.name] as Map<String, dynamic>?;
        if (corner == null) continue;
        if (corner.containsKey('points')) {
          expect(match.points(s), corner['points'], reason: '${s.name} points');
        }
        if (corner.containsKey('warnings')) {
          expect(
            match.warnings(s),
            corner['warnings'],
            reason: '${s.name} warnings',
          );
        }
        if (corner.containsKey('oneHandWarnings')) {
          expect(
            match.oneHandWarnings(s),
            corner['oneHandWarnings'],
            reason: '${s.name} one-hand warnings',
          );
        }
      }
      if (expect_.containsKey('elapsed')) {
        expect(
          match.elapsedAt(now),
          duration(expect_['elapsed']),
          reason: 'elapsed',
        );
      }
      if (expect_.containsKey('running')) {
        expect(match.isRunning(now), expect_['running'], reason: 'running');
      }
      if (expect_.containsKey('started')) {
        expect(match.started, expect_['started'], reason: 'started');
      }
      if (expect_.containsKey('finished')) {
        expect(match.finished, expect_['finished'], reason: 'finished');
      }
      if (expect_.containsKey('endReason')) {
        expect(
          match.endReason(now)?.name.toUpperCase(),
          expect_['endReason'],
          reason: 'end reason',
        );
      }
      if (expect_.containsKey('disqualified')) {
        expect(
          sideToJson(match.disqualified),
          expect_['disqualified'],
          reason: 'disqualified',
        );
      }
      if (expect_.containsKey('lastUndoable')) {
        expect(
          match.lastUndoable?.id,
          expect_['lastUndoable'],
          reason: 'last undoable',
        );
      }
      final autoPoint = expect_['autoPoint'] as Map<String, dynamic>?;
      for (final MapEntry(key: warning, :value) in (autoPoint ?? {}).entries) {
        expect(
          match.gaveAutoPoint(warning),
          value,
          reason: 'warning $warning gave a point',
        );
      }
      final refusals = (expect_['refuse'] as List?)
          ?.cast<Map<String, dynamic>>();
      for (final refusal in refusals ?? const <Map<String, dynamic>>[]) {
        final actual = match.refuse(
          MatchAction.fromWire(refusal['action'] as String),
          now,
          side: side(refusal['side']),
          delta: refusal.containsKey('delta')
              ? duration(refusal['delta'])
              : Duration.zero,
        );
        expect(actual?.name, refusal['expect'], reason: 'refuse $refusal');
      }
    });
  }
}
