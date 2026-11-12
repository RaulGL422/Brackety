/// The group a helper is putting together before sending it to a mat (docs/modulos/prototipo-f1.md):
/// 4 participants, or 3 and a ghost.
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

  /// The ghost box can be ticked while there is room for a ghost (3 or fewer picked), and untick always.
  bool get canToggleGhost => ghostMode || members.length < size;

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

  /// Where [id] stands; [grouped] = already in a group on the server.
  PickState stateOf(String id, {required bool grouped}) {
    if (ghost == id) return PickState.ghost;
    if (members.contains(id)) return PickState.member;
    if (choosingGhost) return PickState.free;
    final full = isComplete || (ghostMode && members.length == size - 1);
    return grouped || full ? PickState.unavailable : PickState.free;
  }

  DraftGroup toggle(String id, {required bool grouped}) {
    switch (stateOf(id, grouped: grouped)) {
      case PickState.ghost:
        return copyWith(ghost: () => null);
      case PickState.member:
        return copyWith(
          members: [...members]..remove(id),
          ghost: () => null,
          ghostTeam: const [],
        );
      case PickState.free:
        return choosingGhost
            ? copyWith(ghost: () => id)
            : copyWith(members: [...members, id]);
      case PickState.unavailable:
        return this;
    }
  }

  /// Without the members in [taken] (someone else put them in a group meanwhile). The ghost and the
  /// ghost team go too, as when a member is taken out by hand.
  DraftGroup without(Set<String> taken) {
    if (!members.any(taken.contains)) return this;
    return copyWith(
      members: [...members.where((id) => !taken.contains(id))],
      ghost: () => null,
      ghostTeam: const [],
    );
  }

  /// The participants of the ghost team, once its 3 teams are picked.
  DraftGroup setGhostTeam(List<String> ids) {
    final ready = ofTeams && ghostMode && members.length == size - 1;
    if (!ready || ids.length > ghostTeamSize!) return this;
    return copyWith(ghostTeam: ids);
  }

  DraftGroup setGhostMode(bool on) {
    var kept = members;
    String? newGhost;
    // Turning it on with 4 picked: the last participant becomes the ghost; a 4th team is dropped,
    // since a ghost team is made of participants.
    if (on && kept.length == size) {
      if (!ofTeams) newGhost = kept.last;
      kept = kept.sublist(0, size - 1);
    }
    return DraftGroup(
      members: kept,
      ghostMode: on,
      ghost: newGhost,
      ghostTeamSize: ghostTeamSize,
    );
  }
}

enum PickState { free, member, ghost, unavailable }
