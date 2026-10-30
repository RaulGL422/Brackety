/// Groups a helper is putting together before sending them to a mat (docs/modulos/prototipo-f1.md):
/// 4 participants, or 3 and a ghost. With multigroup there are several, all for one mat.
class DraftGroup {
  const DraftGroup({
    this.members = const [],
    this.ghostMode = false,
    this.ghost,
  });

  static const size = 4;

  /// In selection order, which becomes the order in the group.
  final List<String> members;

  /// The "ghost competitor" box: the 4th pick is a ghost who fights but does not score.
  final bool ghostMode;
  final String? ghost;

  bool get isComplete => ghostMode
      ? members.length == size - 1 && ghost != null
      : members.length == size;

  /// With 3 picked in ghost mode, the next pick is the ghost.
  bool get choosingGhost =>
      ghostMode && members.length == size - 1 && ghost == null;

  bool contains(String id) => members.contains(id) || ghost == id;

  DraftGroup copyWith({
    List<String>? members,
    bool? ghostMode,
    String? Function()? ghost,
  }) => DraftGroup(
    members: members ?? this.members,
    ghostMode: ghostMode ?? this.ghostMode,
    ghost: ghost == null ? this.ghost : ghost(),
  );
}

enum PickState { free, member, ghost, unavailable }

class GroupDraft {
  const GroupDraft({
    required this.maxGroups,
    this.groups = const [DraftGroup()],
    this.current = 0,
  });

  final int maxGroups;
  final List<DraftGroup> groups;
  final int current;

  DraftGroup get currentGroup => groups[current];

  /// At least one group and every group complete.
  bool get isReady => groups.every((g) => g.isComplete);

  bool get canAddGroup => groups.length < maxGroups && currentGroup.isComplete;

  /// Where [id] stands for the group being built; [grouped] = already in a group on the server.
  PickState stateOf(String id, {required bool grouped}) {
    final group = currentGroup;
    if (group.ghost == id) return PickState.ghost;
    if (group.members.contains(id)) return PickState.member;
    if (group.choosingGhost) return PickState.free;
    final inOtherGroup = [
      for (var i = 0; i < groups.length; i++)
        if (i != current) ...groups[i].members,
    ].contains(id);
    return grouped || inOtherGroup || group.isComplete
        ? PickState.unavailable
        : PickState.free;
  }

  /// The group index [id] belongs to in this draft, as a member or ghost, or null.
  int? groupOf(String id) {
    final index = groups.indexWhere((g) => g.contains(id));
    return index < 0 ? null : index;
  }

  GroupDraft toggle(String id, {required bool grouped}) {
    final group = currentGroup;
    switch (stateOf(id, grouped: grouped)) {
      case PickState.ghost:
        return _withCurrent(group.copyWith(ghost: () => null));
      case PickState.member:
        return _withCurrent(
          group.copyWith(
            members: [...group.members]..remove(id),
            ghost: () => null,
          ),
        );
      case PickState.free:
        return group.choosingGhost
            ? _withCurrent(group.copyWith(ghost: () => id))
            : _withCurrent(group.copyWith(members: [...group.members, id]));
      case PickState.unavailable:
        return this;
    }
  }

  GroupDraft setGhostMode(bool on) {
    final group = currentGroup;
    var members = group.members;
    // Turning it on with 4 picked: the last pick becomes the ghost.
    String? ghost;
    if (on && members.length == DraftGroup.size) {
      ghost = members.last;
      members = members.sublist(0, DraftGroup.size - 1);
    }
    return _withCurrent(
      DraftGroup(members: members, ghostMode: on, ghost: ghost),
    );
  }

  GroupDraft addGroup() => canAddGroup
      ? GroupDraft(
          maxGroups: maxGroups,
          groups: [...groups, const DraftGroup()],
          current: groups.length,
        )
      : this;

  GroupDraft select(int index) =>
      GroupDraft(maxGroups: maxGroups, groups: groups, current: index);

  /// Drops the current group (if there is more than one).
  GroupDraft removeCurrent() {
    if (groups.length == 1) return GroupDraft(maxGroups: maxGroups);
    final rest = [...groups]..removeAt(current);
    return GroupDraft(
      maxGroups: maxGroups,
      groups: rest,
      current: rest.length - 1,
    );
  }

  GroupDraft _withCurrent(DraftGroup group) => GroupDraft(
    maxGroups: maxGroups,
    groups: [...groups]..[current] = group,
    current: current,
  );
}
