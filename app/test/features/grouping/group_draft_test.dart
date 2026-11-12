import 'package:brackety/features/grouping/state/group_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DraftGroup pick(
    DraftGroup draft,
    List<String> ids, {
    Set<String> grouped = const {},
  }) {
    for (final id in ids) {
      draft = draft.toggle(id, grouped: grouped.contains(id));
    }
    return draft;
  }

  test('four picks complete a group and the rest become unavailable', () {
    final draft = pick(const DraftGroup(), ['a', 'b', 'c', 'd']);

    expect(draft.isComplete, isTrue);
    expect(draft.members, ['a', 'b', 'c', 'd']);
    expect(draft.stateOf('e', grouped: false), PickState.unavailable);
    expect(draft.toggle('e', grouped: false).members, hasLength(4));
  });

  test('tapping a pick again removes it', () {
    final draft = pick(const DraftGroup(), ['a', 'b', 'a']);

    expect(draft.members, ['b']);
    expect(draft.isComplete, isFalse);
  });

  test('participants already in a group cannot be picked', () {
    final draft = pick(const DraftGroup(), ['a'], grouped: {'a'});

    expect(draft.members, isEmpty);
    expect(draft.stateOf('a', grouped: true), PickState.unavailable);
  });

  test(
    'in ghost mode the fourth pick is the ghost and may be in a group already',
    () {
      var draft = const DraftGroup().setGhostMode(true);
      draft = pick(draft, ['a', 'b', 'c']);

      expect(draft.choosingGhost, isTrue);
      expect(draft.stateOf('x', grouped: true), PickState.free);
      expect(draft.stateOf('a', grouped: false), PickState.member);

      draft = pick(draft, ['x'], grouped: {'x'});
      expect(draft.ghosts, ['x']);
      expect(draft.stateOf('x', grouped: true), PickState.ghost);
      expect(draft.isComplete, isTrue);
      expect(draft.stateOf('y', grouped: false), PickState.unavailable);
    },
  );

  test('turning ghost mode on with four picks makes the last one the ghost, and off drops it', () {
    var draft = pick(const DraftGroup(), [
      'a',
      'b',
      'c',
      'd',
    ]).setGhostMode(true);

    expect(draft.members, ['a', 'b', 'c']);
    expect(draft.ghosts, ['d']);

    draft = draft.setGhostMode(false);
    expect(draft.members, ['a', 'b', 'c']);
    expect(draft.ghosts, isEmpty);
    expect(draft.isComplete, isFalse);
  });

  test('removing a member in ghost mode keeps the ghost', () {
    var draft = pick(const DraftGroup().setGhostMode(true), [
      'a',
      'b',
      'c',
      'x',
    ]);

    draft = draft.toggle('b', grouped: false);

    expect(draft.members, ['a', 'c']);
    expect(draft.ghosts, ['x']);
  });

  group('groups of teams', () {
    test(
      'three teams and a full ghost team of participants complete a group',
      () {
        var draft = pick(const DraftGroup(ghostTeamSize: 3), [
          't1',
          't2',
          't3',
        ]).setGhostMode(true);

        expect(draft.choosingGhost, isFalse);
        expect(draft.choosingGhostTeam, isTrue);
        expect(draft.stateOf('t4', grouped: false), PickState.unavailable);

        draft = draft.setGhostTeam(['p1', 'p2']);
        expect(draft.isComplete, isFalse);
        expect(draft.setGhostTeam(['p1', 'p2', 'p3', 'p4']), same(draft));

        draft = draft.setGhostTeam(['p1', 'p2', 'p3']);
        expect(draft.isComplete, isTrue);
        expect(draft.ghostTeam, ['p1', 'p2', 'p3']);
      },
    );

    test('turning ghost mode on with four teams drops the fourth, not making it a ghost', () {
      final draft = pick(const DraftGroup(ghostTeamSize: 3), [
        't1',
        't2',
        't3',
        't4',
      ]).setGhostMode(true);

      expect(draft.members, ['t1', 't2', 't3']);
      expect(draft.ghosts, isEmpty);
      expect(draft.choosingGhostTeam, isTrue);
      expect(draft.ofTeams, isTrue);
    });

    test(
      'the ghost team needs its three teams first and goes with a removed team',
      () {
        var draft = pick(
          const DraftGroup(ghostTeamSize: 3).setGhostMode(true),
          ['t1', 't2'],
        );
        expect(draft.setGhostTeam(['p1']), same(draft));

        draft = pick(draft, ['t3']).setGhostTeam(['p1', 'p2', 'p3']);
        draft = pick(draft, ['t2']);
        expect(draft.ghostTeam, isEmpty);
      },
    );
  });

  test(
    'in ghost mode up to three already grouped join as ghosts, with one real',
    () {
      var draft = const DraftGroup().setGhostMode(true);
      draft = pick(draft, ['x', 'y', 'z'], grouped: {'x', 'y', 'z'});

      expect(draft.ghosts, ['x', 'y', 'z']);
      expect(draft.isComplete, isFalse);
      expect(draft.stateOf('w', grouped: true), PickState.unavailable);

      draft = pick(draft, ['a']);
      expect(draft.members, ['a']);
      expect(draft.isComplete, isTrue);
    },
  );

  test('members someone else grouped leave the draft, the ghost stays', () {
    final draft = const DraftGroup()
        .setGhostMode(true)
        .toggle('a', grouped: false)
        .toggle('b', grouped: false)
        .toggle('c', grouped: false)
        .toggle('g', grouped: true);

    final left = draft.without({'b'});

    expect(left.members, ['a', 'c']);
    expect(left.ghosts, ['g']);
    expect(identical(draft.without({'x'}), draft), isTrue);
  });

  test('with 4 picked the ghost box cannot be ticked', () {
    var draft = const DraftGroup();
    for (final id in ['a', 'b', 'c']) {
      draft = draft.toggle(id, grouped: false);
    }
    expect(draft.canToggleGhost, isTrue);

    draft = draft.toggle('d', grouped: false);
    expect(draft.canToggleGhost, isFalse);
    expect(draft.setGhostMode(true).canToggleGhost, isTrue);
  });
}
