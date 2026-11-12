class CategorySummary {
  const CategorySummary({
    required this.id,
    required this.name,
    required this.participants,
    required this.grouped,
    this.teamSize,
    this.teams = 0,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) =>
      CategorySummary(
        id: json['id'] as String,
        name: json['name'] as String,
        participants: json['participants'] as int,
        grouped: json['grouped'] as int,
        teamSize: json['format'] == 'TEAM' ? json['teamSize'] as int : null,
        teams: json['teams'] as int? ?? 0,
      );

  final String id;
  final String name;
  final int participants;

  /// Competing in a group, directly or through their team.
  final int grouped;

  /// Null in an individual category.
  final int? teamSize;
  final int teams;

  bool get isTeam => teamSize != null;
}

class CategoryParticipant {
  const CategoryParticipant({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.age,
    this.heightCm,
    this.groupNumber,
    this.matNumber,
    this.teamNumber,
    this.groupId,
    this.groupStarted = false,
  });

  factory CategoryParticipant.fromJson(Map<String, dynamic> json) =>
      CategoryParticipant(
        id: json['id'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        age: json['age'] as int,
        heightCm: json['heightCm'] as int?,
        groupNumber: json['groupNumber'] as int?,
        matNumber: json['matNumber'] as int?,
        teamNumber: json['teamNumber'] as int?,
        groupId: json['groupId'] as String?,
        groupStarted: json['groupStarted'] as bool? ?? false,
      );

  final String id;
  final String firstName;
  final String lastName;
  final int age;
  final int? heightCm;

  /// Set once the participant competes in a group (not as a ghost).
  final int? groupNumber;
  final int? matNumber;

  /// Set once the participant is in a real team (not a ghost one).
  final int? teamNumber;

  final String? groupId;

  /// A match of their group has started: the helper can no longer undo it.
  final bool groupStarted;

  bool get canUndoGroup => groupId != null && !groupStarted;

  bool get isGrouped => groupNumber != null;

  /// Already competing for real somewhere: a group or a team.
  bool get isTaken => isGrouped || teamNumber != null;

  String get fullName => '$firstName $lastName';
}

class CreatedGroups {
  const CreatedGroups({
    required this.matNumber,
    required this.groupNumbers,
    this.groupIds = const [],
  });

  factory CreatedGroups.fromJson(Map<String, dynamic> json) => CreatedGroups(
    matNumber: json['matNumber'] as int,
    groupNumbers: [for (final n in json['groupNumbers'] as List) n as int],
    groupIds: [for (final id in json['groupIds'] as List? ?? []) id as String],
  );

  final int matNumber;
  final List<int> groupNumbers;

  /// In the order of [groupNumbers].
  final List<String> groupIds;
}

/// "Equipo N" of a team category; [groupNumber] and [matNumber] are null until it is in a group.
class Team {
  const Team({
    required this.id,
    required this.number,
    required this.members,
    this.groupNumber,
    this.matNumber,
    this.groupId,
    this.groupStarted = false,
  });

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    id: json['id'] as String,
    number: json['number'] as int,
    members: [
      for (final m in json['members'] as List)
        TeamMember(
          participantId: (m as Map<String, dynamic>)['participantId'] as String,
          fullName: '${m['firstName']} ${m['lastName']}',
          ghost: m['ghost'] as bool? ?? false,
        ),
    ],
    groupNumber: json['groupNumber'] as int?,
    matNumber: json['matNumber'] as int?,
    groupId: json['groupId'] as String?,
    groupStarted: json['groupStarted'] as bool? ?? false,
  );

  final String id;
  final int number;
  final List<TeamMember> members;
  final int? groupNumber;
  final int? matNumber;
  final String? groupId;
  final bool groupStarted;

  bool get isGrouped => groupNumber != null;

  bool get canUndoGroup => groupId != null && !groupStarted;
}

class TeamMember {
  const TeamMember({
    required this.participantId,
    required this.fullName,
    this.ghost = false,
  });

  final String participantId;
  final String fullName;

  /// Fills the team in (they compete elsewhere) without scoring for it.
  final bool ghost;
}

/// Participants in more than one of [teams], with the numbers of the teams they are in. A team's
/// ghost member may be in another team of the same group: allowed, but the helper should know.
Map<String, List<int>> overlappingMembers(List<Team> teams) {
  final teamsOf = <String, List<int>>{};
  for (final t in teams) {
    for (final m in t.members) {
      (teamsOf[m.participantId] ??= []).add(t.number);
    }
  }
  return {
    for (final MapEntry(:key, :value) in teamsOf.entries)
      if (value.length > 1) key: value,
  };
}
