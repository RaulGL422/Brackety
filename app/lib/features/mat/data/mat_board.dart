enum MatchStatus { pending, inProgress, finished }

MatchStatus matchStatusFromJson(String value) => switch (value) {
  'PENDING' => MatchStatus.pending,
  'IN_PROGRESS' => MatchStatus.inProgress,
  _ => MatchStatus.finished,
};

/// What every screen shows of a fighter: a participant, or a team called by its number.
abstract interface class FighterInfo {
  String get name;

  /// Set for a team ("Equipo N"); [members] are then its participants.
  int? get teamNumber;
  List<String> get members;

  /// Fights but scores nothing.
  bool get ghost;
}

class Fighter implements FighterInfo {
  const Fighter({
    required this.participantId,
    required this.name,
    required this.ghost,
    this.teamNumber,
    this.members = const [],
  });

  factory Fighter.fromJson(Map<String, dynamic> json) => Fighter(
    participantId: json['participantId'] as String?,
    name: json['name'] as String,
    ghost: json['ghost'] as bool,
    teamNumber: json['teamNumber'] as int?,
    members: [for (final m in json['members'] as List? ?? []) m as String],
  );

  /// Null for a team.
  final String? participantId;
  @override
  final String name;
  @override
  final bool ghost;
  @override
  final int? teamNumber;
  @override
  final List<String> members;
}

class BoardGroup {
  const BoardGroup({
    required this.id,
    required this.number,
    required this.categoryName,
    required this.members,
    this.createdBy,
  });

  factory BoardGroup.fromJson(Map<String, dynamic> json) => BoardGroup(
    id: json['id'] as String,
    number: json['number'] as int,
    categoryName: json['categoryName'] as String,
    members: [
      for (final m in json['members'] as List)
        Fighter.fromJson(m as Map<String, dynamic>),
    ],
    createdBy: json['createdBy'] as String?,
  );

  final String id;
  final int number;
  final String categoryName;
  final List<Fighter> members;

  /// Who made the group ("Ana López (ayudante1)", or the sign-in alone).
  final String? createdBy;
}

class BoardMatch {
  const BoardMatch({
    required this.id,
    required this.groupId,
    required this.groupNumber,
    required this.red,
    required this.blue,
    required this.status,
    required this.redScore,
    required this.blueScore,
    required this.available,
    this.inReview = false,
  });

  factory BoardMatch.fromJson(Map<String, dynamic> json) => BoardMatch(
    id: json['id'] as String,
    groupId: json['groupId'] as String,
    groupNumber: json['groupNumber'] as int,
    red: Fighter.fromJson(json['red'] as Map<String, dynamic>),
    blue: Fighter.fromJson(json['blue'] as Map<String, dynamic>),
    status: matchStatusFromJson(json['status'] as String),
    redScore: json['redScore'] as int,
    blueScore: json['blueScore'] as int,
    available: json['available'] as bool,
    inReview: json['inReview'] as bool? ?? false,
  );

  final String id;
  final String groupId;
  final int groupNumber;
  final Fighter red;
  final Fighter blue;
  final MatchStatus status;
  final int redScore;
  final int blueScore;

  /// Pending, not in review and neither fighter is in a match on any mat right now.
  final bool available;

  /// An offline action clashed: it waits for the club and cannot start.
  final bool inReview;

  BoardMatch copyWith({
    MatchStatus? status,
    int? redScore,
    int? blueScore,
    bool? available,
    bool? inReview,
  }) => BoardMatch(
    id: id,
    groupId: groupId,
    groupNumber: groupNumber,
    red: red,
    blue: blue,
    status: status ?? this.status,
    redScore: redScore ?? this.redScore,
    blueScore: blueScore ?? this.blueScore,
    available: available ?? this.available,
    inReview: inReview ?? this.inReview,
  );
}

class MatBoard {
  const MatBoard({
    required this.matNumber,
    required this.groups,
    required this.matches,
    this.recommendedMatchId,
    this.offline = false,
  });

  factory MatBoard.fromJson(Map<String, dynamic> json) => MatBoard(
    matNumber: json['matNumber'] as int,
    groups: [
      for (final g in json['groups'] as List)
        BoardGroup.fromJson(g as Map<String, dynamic>),
    ],
    matches: [
      for (final m in json['matches'] as List)
        BoardMatch.fromJson(m as Map<String, dynamic>),
    ],
    recommendedMatchId: json['recommendedMatchId'] as String?,
  );

  final int matNumber;
  final List<BoardGroup> groups;
  final List<BoardMatch> matches;
  final String? recommendedMatchId;

  /// From the device's cache: the server did not answer.
  final bool offline;
}
