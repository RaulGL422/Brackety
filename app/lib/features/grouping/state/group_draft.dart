/// Groups a helper is putting together before sending them to a mat (docs/modulos/prototipo-f1.md):
/// 4 participants, or 3 and a ghost. With multigroup there are several, all for one mat.
///
/// In a team category (docs/modulos/prototipo-f1-equipos.md) the members are teams and the ghost
/// is a ghost team: [ghostTeamSize] participants picked from the category's list, not a team.
class DraftGroup {
  const DraftGroup({
    this.members = const [],
    this.ghostMode = false,
    this.ghost,
    this.ghostTeam = const [],
    this.ghostTeamSize,
  });

  static const size = 4;

  /// In selection order, which becomes the order in the group.
  final List<String> members;

  /// The ghost box: the 4th member fights but does not score.
  final bool ghostMode;

  /// The ghost participant of a group of participants.
  final String? ghost;

  /// The participants of the ghost team of a group of teams, in selection order.
  final List<String> ghostTeam;

  /// Null in a group of participants.
  final int? ghostTeamSize;

  bool get ofTeams => ghostTeamSize != null;

  bool get isComplete {
    if (!ghostMode) return members.length == size;
    final ghostDone = ofTeams
        ? ghostTeam.length == ghostTeamSize
        : ghost != null;
    return members.length == size - 1 && ghostDone;
  }

  /// With 3 participants picked in ghost mode, the next pick is the ghost.
  bool get choosingGhost =>
      !ofTeams && ghostMode && members.length == size - 1 && ghost == null;

  /// With 3 teams picked in ghost mode, the ghost team is still missing people.
  bool get choosingGhostTeam =>
      ofTeams && ghostMode && members.length == size - 1 && !isComplete;

  bool contains(String id) => members.contains(id) || ghost == id;

  DraftGroup copyWith({
    List<String>? members,
    bool? ghostMode,
    String? Function()? ghost,
    List<String>? ghostTeam,
  }) => DraftGroup(
    members: members ?? this.members,
    ghostMode: ghostMode ?? this.ghostMode,
    ghost: ghost == null ? this.ghost : ghost(),
    ghostTeam: ghostTeam ?? this.ghostTeam,
    ghostTeamSize: ghostTeamSize,
  );
}

enum PickState { free, member, ghost, unavailable }

class GroupDraft {
  GroupDraft({
    required this.maxGroups,
    this.ghostTeamSize,
    List<DraftGroup>? groups,
    this.current = 0,
  }) : groups = groups ?? [DraftGroup(ghostTeamSize: ghostTeamSize)];

  final int maxGroups;

  /// Set for groups of teams: the size of the category's teams.
  final int? ghostTeamSize;
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
    final full =
        group.isComplete ||
        (group.ghostMode && group.members.length == DraftGroup.size - 1);
    return grouped || inOtherGroup || full
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
            ghostTeam: const [],
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

  /// The participants of the current group's ghost team, once its 3 teams are picked.
  GroupDraft setGhostTeam(List<String> ids) {
    final group = currentGroup;
    final ready =
        group.ofTeams &&
        group.ghostMode &&
        group.members.length == DraftGroup.size - 1;
    if (!ready || ids.length > ghostTeamSize!) return this;
    return _withCurrent(group.copyWith(ghostTeam: ids));
  }

  GroupDraft setGhostMode(bool on) {
    final group = currentGroup;
    var members = group.members;
    String? ghost;
    // Turning it on with 4 picked: the last participant becomes the ghost; a 4th team is dropped,
    // since a ghost team is made of participants.
    if (on && members.length == DraftGroup.size) {
      if (!group.ofTeams) ghost = members.last;
      members = members.sublist(0, DraftGroup.size - 1);
    }
    return _withCurrent(
      DraftGroup(
        members: members,
        ghostMode: on,
        ghost: ghost,
        ghostTeamSize: ghostTeamSize,
      ),
    );
  }

  GroupDraft addGroup() => canAddGroup
      ? _copy(
          groups: [
            ...groups,
            DraftGroup(ghostTeamSize: ghostTeamSize),
          ],
          current: groups.length,
        )
      : this;

  GroupDraft select(int index) => _copy(groups: groups, current: index);

  /// Drops the current group (if there is more than one).
  GroupDraft removeCurrent() {
    if (groups.length == 1) {
      return GroupDraft(maxGroups: maxGroups, ghostTeamSize: ghostTeamSize);
    }
    final rest = [...groups]..removeAt(current);
    return _copy(groups: rest, current: rest.length - 1);
  }

  GroupDraft _withCurrent(DraftGroup group) =>
      _copy(groups: [...groups]..[current] = group, current: current);

  GroupDraft _copy({required List<DraftGroup> groups, required int current}) =>
      GroupDraft(
        maxGroups: maxGroups,
        ghostTeamSize: ghostTeamSize,
        groups: groups,
        current: current,
      );
}
