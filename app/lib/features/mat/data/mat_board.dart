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

/// Why a pending match cannot start now.
enum WaitReason { review, busy, resting, otherMat }

WaitReason? waitReasonFromJson(String? value) => switch (value) {
  'REVIEW' => WaitReason.review,
  'BUSY' => WaitReason.busy,
  'RESTING' => WaitReason.resting,
  'OTHER_MAT' => WaitReason.otherMat,
  _ => null,
};

/// Where a pending match's fighter (every person of a team) is now, so the referee knows when to
/// call them: fighting on a mat, free at a time (an estimate while fighting; null if free now) and
/// the mats where they still have other matches, one entry per match.
class CornerState {
  const CornerState({
    this.fightingOnMat,
    this.freeAt,
    this.pendingMats = const [],
  });

  factory CornerState.fromJson(Map<String, dynamic> json) => CornerState(
    fightingOnMat: json['fightingOnMat'] as int?,
    freeAt: switch (json['freeAt']) {
      final String at => DateTime.parse(at),
      _ => null,
    },
    pendingMats: [for (final m in json['pendingMats'] as List? ?? []) m as int],
  );

  final int? fightingOnMat;
  final DateTime? freeAt;
  final List<int> pendingMats;
}

CornerState? _corner(Object? json) =>
    json is Map<String, dynamic> ? CornerState.fromJson(json) : null;

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
    this.waitReason,
    this.readyAt,
    this.otherMatNumber,
    this.pool = false,
    this.redCorner,
    this.blueCorner,
    this.plannedAt,
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
    waitReason: waitReasonFromJson(json['waitReason'] as String?),
    readyAt: switch (json['readyAt']) {
      final String at => DateTime.parse(at),
      _ => null,
    },
    otherMatNumber: json['otherMatNumber'] as int?,
    pool: json['pool'] as bool? ?? false,
    redCorner: _corner(json['redCorner']),
    blueCorner: _corner(json['blueCorner']),
    plannedAt: switch (json['plannedAt']) {
      final String at => DateTime.parse(at),
      _ => null,
    },
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

  /// Why it cannot start now; null if it can (or the server is older).
  final WaitReason? waitReason;

  /// [WaitReason.resting]: when every fighter will have had the least rest.
  final DateTime? readyAt;

  /// [WaitReason.otherMat]: the mat it is proposed to.
  final int? otherMatNumber;

  /// A team match from the pool shared by the mats without individual matches.
  final bool pool;

  /// Pending: where each fighter is now (null from an older server).
  final CornerState? redCorner;
  final CornerState? blueCorner;

  /// Pending: when it would start on this mat if all goes as planned (an estimate).
  final DateTime? plannedAt;

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
    waitReason: waitReason,
    readyAt: readyAt,
    otherMatNumber: otherMatNumber,
    pool: pool,
    redCorner: redCorner,
    blueCorner: blueCorner,
    plannedAt: plannedAt,
  );
}

/// A mat of the event, to send a match to: only one with a referee takes it.
class MatChoice {
  const MatChoice({
    required this.id,
    required this.number,
    required this.hasReferee,
  });

  factory MatChoice.fromJson(Map<String, dynamic> json) => MatChoice(
    id: json['id'] as String,
    number: json['number'] as int,
    hasReferee: json['hasReferee'] as bool,
  );

  final String id;
  final int number;
  final bool hasReferee;
}

class MatBoard {
  const MatBoard({
    required this.matNumber,
    required this.groups,
    required this.matches,
    this.recommendedMatchId,
    this.offline = false,
    this.teamPool = false,
    this.eventId,
    this.mats = const [],
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
    teamPool: json['teamPool'] as bool? ?? false,
    eventId: json['eventId'] as String?,
    mats: [
      for (final m in json['mats'] as List? ?? const [])
        MatChoice.fromJson(m as Map<String, dynamic>),
    ],
  );

  final int matNumber;
  final List<BoardGroup> groups;
  final List<BoardMatch> matches;
  final String? recommendedMatchId;

  /// From the device's cache: the server did not answer.
  final bool offline;

  /// No individual match is pending here: the mat takes team matches from the shared pool.
  final bool teamPool;

  /// The phase: its rulebook opens from the mat. Null in a board cached before it was sent.
  final String? eventId;

  /// The event's mats.
  final List<MatChoice> mats;
}
