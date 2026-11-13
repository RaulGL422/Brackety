/// The group a helper is putting together before sending it to a mat (docs/modulos/prototipo-f1.md):
/// 4 participants, up to 3 of them wildcards.
///
/// In a team category (docs/modulos/prototipo-f1-equipos.md) the members are teams and up to 3
/// wildcard teams fill the group in: each one 2 or 3 participants picked from the category's list.
class DraftGroup {
  const DraftGroup({
    this.members = const [],
    this.ghostMode = false,
    this.ghosts = const [],
    this.ghostTeams = const [],
    this.ofTeams = false,
  });

  static const size = 4;

  /// Teams are of 2 or 3, always (Raul, 2026-11-13).
  static const minTeam = 2;
  static const maxTeam = 3;

  /// In selection order, which becomes the order in the group.
  final List<String> members;

  /// The wildcard box: someone already in a group, or the 4th pick, fights but does not score.
  final bool ghostMode;

  /// The wildcard participants of a group of participants, in selection order.
  final List<String> ghosts;

  /// The participants of each wildcard team of a group of teams, in selection order.
  final List<List<String>> ghostTeams;

  final bool ofTeams;

  int get _filled => members.length + (ofTeams ? ghostTeams.length : 0);

  bool get isComplete {
    if (!ghostMode) return members.length == size;
    if (ofTeams) return members.isNotEmpty && _filled == size;
    return members.isNotEmpty &&
        ghosts.isNotEmpty &&
        members.length + ghosts.length == size;
  }

  /// With 3 participants picked in wildcard mode, the next pick is the wildcard.
  bool get choosingGhost =>
      !ofTeams && ghostMode && members.length == size - 1 && ghosts.isEmpty;

  /// In wildcard mode there is room for another wildcard team (at least one team stays real).
  bool get canAddGhostTeam =>
      ofTeams && ghostMode && _filled < size && ghostTeams.length < size - 1;

  bool contains(String id) => members.contains(id) || ghosts.contains(id);

  /// The wildcard box can be ticked while there is room for a wildcard (3 or fewer picked), and untick always.
  bool get canToggleGhost => ghostMode || members.length < size;

  DraftGroup copyWith({
    List<String>? members,
    bool? ghostMode,
    List<String>? ghosts,
    List<List<String>>? ghostTeams,
  }) => DraftGroup(
    members: members ?? this.members,
    ghostMode: ghostMode ?? this.ghostMode,
    ghosts: ghosts ?? this.ghosts,
    ghostTeams: ghostTeams ?? this.ghostTeams,
    ofTeams: ofTeams,
  );

  /// Where [id] stands; [grouped] = already in a group on the server.
  PickState stateOf(String id, {required bool grouped}) {
    if (ghosts.contains(id)) return PickState.ghost;
    if (members.contains(id)) return PickState.member;
    if (ofTeams) {
      return grouped || _filled == size
          ? PickState.unavailable
          : PickState.free;
    }
    if (members.length + ghosts.length == size) return PickState.unavailable;
    if (_picksGhost(grouped)) {
      return ghosts.length < size - 1 ? PickState.free : PickState.unavailable;
    }
    return grouped ? PickState.unavailable : PickState.free;
  }

  /// In wildcard mode, someone already in a group joins as a wildcard, and so does the pick after 3 real ones.
  bool _picksGhost(bool grouped) =>
      !ofTeams && ghostMode && (grouped || members.length == size - 1);

  DraftGroup toggle(String id, {required bool grouped}) {
    switch (stateOf(id, grouped: grouped)) {
      case PickState.ghost:
        return copyWith(ghosts: [...ghosts]..remove(id));
      case PickState.member:
        return copyWith(members: [...members]..remove(id));
      case PickState.free:
        return _picksGhost(grouped)
            ? copyWith(ghosts: [...ghosts, id])
            : copyWith(members: [...members, id]);
      case PickState.unavailable:
        return this;
    }
  }

  /// Without the members in [taken] (someone else put them in a group meanwhile).
  DraftGroup without(Set<String> taken) {
    if (!members.any(taken.contains)) return this;
    return copyWith(members: [...members.where((id) => !taken.contains(id))]);
  }

  /// One more wildcard team of 2 or 3 participants, if there is room.
  DraftGroup addGhostTeam(List<String> ids) {
    if (!canAddGhostTeam || ids.length < minTeam || ids.length > maxTeam) {
      return this;
    }
    return copyWith(ghostTeams: [...ghostTeams, ids]);
  }

  DraftGroup removeGhostTeam(int index) =>
      copyWith(ghostTeams: [...ghostTeams]..removeAt(index));

  /// The participants of its wildcard teams; with those of its real teams, nobody else may join.
  Set<String> get ghostTeamPeople => {for (final t in ghostTeams) ...t};

  DraftGroup setGhostMode(bool on) {
    var kept = members;
    var newGhosts = const <String>[];
    // Turning it on with 4 picked: the last participant becomes the wildcard; a 4th team is
    // dropped, since a wildcard team is made of participants.
    if (on && kept.length == size) {
      if (!ofTeams) newGhosts = [kept.last];
      kept = kept.sublist(0, size - 1);
    }
    return DraftGroup(
      members: kept,
      ghostMode: on,
      ghosts: newGhosts,
      ofTeams: ofTeams,
    );
  }
}

enum PickState { free, member, ghost, unavailable }
