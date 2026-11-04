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

  bool get isGrouped => groupNumber != null;

  /// Already competing for real somewhere: a group or a team.
  bool get isTaken => isGrouped || teamNumber != null;

  String get fullName => '$firstName $lastName';
}

class CreatedGroups {
  const CreatedGroups({required this.matNumber, required this.groupNumbers});

  factory CreatedGroups.fromJson(Map<String, dynamic> json) => CreatedGroups(
    matNumber: json['matNumber'] as int,
    groupNumbers: [for (final n in json['groupNumbers'] as List) n as int],
  );

  final int matNumber;
  final List<int> groupNumbers;
}

/// "Equipo N" of a team category; [groupNumber] and [matNumber] are null until it is in a group.
class Team {
  const Team({
    required this.id,
    required this.number,
    required this.members,
    this.groupNumber,
    this.matNumber,
  });

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    id: json['id'] as String,
    number: json['number'] as int,
    members: [
      for (final m in json['members'] as List)
        TeamMember(
          participantId: (m as Map<String, dynamic>)['participantId'] as String,
          fullName: '${m['firstName']} ${m['lastName']}',
        ),
    ],
    groupNumber: json['groupNumber'] as int?,
    matNumber: json['matNumber'] as int?,
  );

  final String id;
  final int number;
  final List<TeamMember> members;
  final int? groupNumber;
  final int? matNumber;

  bool get isGrouped => groupNumber != null;
}

class TeamMember {
  const TeamMember({required this.participantId, required this.fullName});

  final String participantId;
  final String fullName;
}
