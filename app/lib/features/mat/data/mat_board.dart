enum MatchStatus { pending, inProgress, finished }

MatchStatus matchStatusFromJson(String value) => switch (value) {
  'PENDING' => MatchStatus.pending,
  'IN_PROGRESS' => MatchStatus.inProgress,
  _ => MatchStatus.finished,
};

class Fighter {
  const Fighter({
    required this.participantId,
    required this.name,
    required this.ghost,
  });

  factory Fighter.fromJson(Map<String, dynamic> json) => Fighter(
    participantId: json['participantId'] as String,
    name: json['name'] as String,
    ghost: json['ghost'] as bool,
  );

  final String participantId;
  final String name;

  /// Fights in this group but scores nothing in it.
  final bool ghost;
}

class BoardGroup {
  const BoardGroup({
    required this.id,
    required this.number,
    required this.categoryName,
    required this.members,
  });

  factory BoardGroup.fromJson(Map<String, dynamic> json) => BoardGroup(
    id: json['id'] as String,
    number: json['number'] as int,
    categoryName: json['categoryName'] as String,
    members: [
      for (final m in json['members'] as List)
        Fighter.fromJson(m as Map<String, dynamic>),
    ],
  );

  final String id;
  final int number;
  final String categoryName;
  final List<Fighter> members;
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
  );

  final String id;
  final String groupId;
  final int groupNumber;
  final Fighter red;
  final Fighter blue;
  final MatchStatus status;
  final int redScore;
  final int blueScore;

  /// Pending and neither fighter is in a match on any mat right now.
  final bool available;
}

class MatBoard {
  const MatBoard({
    required this.matNumber,
    required this.groups,
    required this.matches,
    this.recommendedMatchId,
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

  /// Position of the group on this mat, which picks its colour.
  int groupIndex(String groupId) => groups.indexWhere((g) => g.id == groupId);
}
