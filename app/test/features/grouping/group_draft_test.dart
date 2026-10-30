import 'package:brackety/features/grouping/state/group_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  GroupDraft pick(
    GroupDraft draft,
    List<String> ids, {
    Set<String> grouped = const {},
  }) {
    for (final id in ids) {
      draft = draft.toggle(id, grouped: grouped.contains(id));
    }
    return draft;
  }

  test('four picks complete a group and the rest become unavailable', () {
    final draft = pick(const GroupDraft(maxGroups: 1), ['a', 'b', 'c', 'd']);

    expect(draft.isReady, isTrue);
    expect(draft.currentGroup.members, ['a', 'b', 'c', 'd']);
    expect(draft.stateOf('e', grouped: false), PickState.unavailable);
    expect(
      draft.toggle('e', grouped: false).currentGroup.members,
      hasLength(4),
    );
  });

  test('tapping a pick again removes it', () {
    final draft = pick(const GroupDraft(maxGroups: 1), ['a', 'b', 'a']);

    expect(draft.currentGroup.members, ['b']);
    expect(draft.isReady, isFalse);
  });

  test('participants already in a group cannot be picked', () {
    final draft = pick(const GroupDraft(maxGroups: 1), ['a'], grouped: {'a'});

    expect(draft.currentGroup.members, isEmpty);
    expect(draft.stateOf('a', grouped: true), PickState.unavailable);
  });

  test(
    'in ghost mode the fourth pick is the ghost and may be in a group already',
    () {
      var draft = const GroupDraft(maxGroups: 1).setGhostMode(true);
      draft = pick(draft, ['a', 'b', 'c']);

      expect(draft.currentGroup.choosingGhost, isTrue);
      expect(draft.stateOf('x', grouped: true), PickState.free);
      expect(draft.stateOf('a', grouped: false), PickState.member);

      draft = pick(draft, ['x'], grouped: {'x'});
      expect(draft.currentGroup.ghost, 'x');
      expect(draft.stateOf('x', grouped: true), PickState.ghost);
      expect(draft.isReady, isTrue);
      expect(draft.stateOf('y', grouped: false), PickState.unavailable);
    },
  );

  test('turning ghost mode on with four picks makes the last one the ghost, and off drops it', () {
    var draft = pick(const GroupDraft(maxGroups: 1), [
      'a',
      'b',
      'c',
      'd',
    ]).setGhostMode(true);

    expect(draft.currentGroup.members, ['a', 'b', 'c']);
    expect(draft.currentGroup.ghost, 'd');

    draft = draft.setGhostMode(false);
    expect(draft.currentGroup.members, ['a', 'b', 'c']);
    expect(draft.currentGroup.ghost, isNull);
    expect(draft.isReady, isFalse);
  });

  test('removing a member in ghost mode also clears the ghost', () {
    var draft = pick(const GroupDraft(maxGroups: 1).setGhostMode(true), [
      'a',
      'b',
      'c',
      'x',
    ]);

    draft = draft.toggle('b', grouped: false);

    expect(draft.currentGroup.members, ['a', 'c']);
    expect(draft.currentGroup.ghost, isNull);
  });

  test('multigroup adds groups up to the limit, each with its own members', () {
    var draft = pick(const GroupDraft(maxGroups: 2), ['a', 'b', 'c', 'd']);
    expect(draft.canAddGroup, isTrue);

    draft = draft.addGroup();
    expect(draft.current, 1);
    expect(draft.isReady, isFalse);
    expect(draft.stateOf('a', grouped: false), PickState.unavailable);
    expect(draft.groupOf('a'), 0);

    draft = pick(draft, ['e', 'f', 'g', 'h']);
    expect(draft.isReady, isTrue);
    expect(draft.groupOf('h'), 1);
    expect(draft.canAddGroup, isFalse);
    expect(draft.addGroup().groups, hasLength(2));
  });

  test('a group can only be added once the current one is complete, and removed again', () {
    var draft = pick(const GroupDraft(maxGroups: 3), ['a', 'b']);
    expect(draft.canAddGroup, isFalse);

    draft = pick(draft, ['c', 'd']).addGroup().removeCurrent();
    expect(draft.groups, hasLength(1));
    expect(draft.isReady, isTrue);
  });
}
