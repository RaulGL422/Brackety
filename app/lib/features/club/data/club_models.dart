import '../../mat/data/mat_board.dart';

/// A helper or referee account of the event; [personName]: who is behind it, set by the club.
class StaffMember {
  const StaffMember({
    required this.id,
    required this.username,
    this.personName,
    this.roles = const [],
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
    id: json['id'] as String,
    username: json['username'] as String,
    personName: json['personName'] as String?,
    roles: [for (final r in json['roles'] as List? ?? const []) r as String],
  );

  final String id;
  final String username;
  final String? personName;

  /// GROUPER and/or REFEREE.
  final List<String> roles;

  /// "Juan Pérez (arbitro1)", or the sign-in alone; as the server labels them.
  String get label => personName == null ? username : '$personName ($username)';
}

/// An age band of the event; [teamSize] is null when it competes individually.
class EventCategory {
  const EventCategory({
    this.id,
    required this.name,
    required this.minAge,
    required this.maxAge,
    this.teamSize,
    this.groupSize = 4,
  });

  factory EventCategory.fromJson(Map<String, dynamic> json) => EventCategory(
    id: json['id'] as String,
    name: json['name'] as String,
    minAge: json['minAge'] as int,
    maxAge: json['maxAge'] as int,
    teamSize: json['format'] == 'TEAM' ? json['teamSize'] as int? : null,
    groupSize: json['groupSize'] as int? ?? 4,
  );

  /// Null for a category not saved yet.
  final String? id;
  final String name;
  final int minAge;
  final int maxAge;
  final int? teamSize;

  /// Participants or teams per group; only 4 for now.
  final int groupSize;

  bool get isTeam => teamSize != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'minAge': minAge,
    'maxAge': maxAge,
    'format': isTeam ? 'TEAM' : 'INDIVIDUAL',
    'teamSize': teamSize,
    'groupSize': groupSize,
  };
}

class EventSettings {
  const EventSettings({
    required this.name,
    required this.date,
    required this.matReferees,
    required this.referees,
    this.staff = const [],
    required this.categories,
    required this.matchLength,
    required this.pointsLimit,
    required this.attendancePoints,
    this.organizations = const [],
    this.teamMatchLength = const Duration(minutes: 3),
    this.teamPointsLimit = 0,
    this.minRest = const Duration(seconds: 30),
  });

  factory EventSettings.fromJson(Map<String, dynamic> json) {
    final mats = [
      for (final m in json['mats'] as List) m as Map<String, dynamic>,
    ]..sort((a, b) => (a['number'] as int).compareTo(b['number'] as int));
    return EventSettings(
      name: json['name'] as String,
      date: DateTime.parse(json['date'] as String),
      matReferees: [for (final m in mats) m['refereeId'] as String?],
      referees: [
        for (final r in json['referees'] as List)
          StaffMember.fromJson(r as Map<String, dynamic>),
      ],
      staff: [
        for (final s in json['staff'] as List? ?? const [])
          StaffMember.fromJson(s as Map<String, dynamic>),
      ],
      categories: [
        for (final c in json['categories'] as List)
          EventCategory.fromJson(c as Map<String, dynamic>),
      ],
      matchLength: Duration(seconds: json['matchSeconds'] as int),
      pointsLimit: json['pointsLimit'] as int,
      attendancePoints: json['attendancePoints'] as int,
      organizations: [
        for (final o in json['organizations'] as List? ?? [])
          Organization.fromJson(o as Map<String, dynamic>),
      ],
      teamMatchLength: Duration(
        seconds: json['teamMatchSeconds'] as int? ?? 180,
      ),
      teamPointsLimit: json['teamPointsLimit'] as int? ?? 0,
      minRest: Duration(seconds: json['minRestSeconds'] as int? ?? 30),
    );
  }

  final String name;
  final DateTime date;

  /// One entry per mat, mat 1 first: the referee's account id, or null.
  final List<String?> matReferees;

  /// Accounts that can referee a mat in this event.
  final List<StaffMember> referees;

  /// Every helper and referee, with the person behind each account.
  final List<StaffMember> staff;
  final List<EventCategory> categories;
  final Duration matchLength;

  /// Points that end a match; a disqualification gives them to the rival.
  final int pointsLimit;

  /// Points everyone in a group of this phase adds to the standings.
  final int attendancePoints;

  /// Team matches have their own length and points limit (0 = no limit).
  final Duration teamMatchLength;
  final int teamPointsLimit;

  /// The least rest of a fighter between two matches, on any mat.
  final Duration minRest;

  /// The clubs taking part, in the order the club entered them.
  final List<Organization> organizations;
}

/// A club taking part in the event; [id] is null until saved.
class Organization {
  const Organization({this.id, required this.name, this.shortName});

  factory Organization.fromJson(Map<String, dynamic> json) => Organization(
    id: json['id'] as String?,
    name: json['name'] as String,
    shortName: json['shortName'] as String?,
  );

  final String? id;
  final String name;
  final String? shortName;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'shortName': shortName,
  };
}

/// From this age on the day of the event no guardian has to agree.
const adultAge = 18;

class Participant {
  const Participant({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.guardianConsent,
    required this.age,
    this.heightCm,
    this.categoryName,
    this.chosenCategoryId,
    this.organizationId,
    this.organizationName,
  });

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
    id: json['id'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    birthDate: DateTime.parse(json['birthDate'] as String),
    guardianConsent: json['guardianConsent'] as bool,
    age: json['age'] as int,
    heightCm: json['heightCm'] as int?,
    categoryName: json['categoryName'] as String?,
    chosenCategoryId: json['chosenCategoryId'] as String?,
    organizationId: json['organizationId'] as String?,
    organizationName: json['organizationName'] as String?,
  );

  final String id;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final bool guardianConsent;

  /// Age on the day of the event.
  final int age;
  final int? heightCm;

  /// Null when no category of the event covers the age.
  final String? categoryName;

  /// Set when a category was chosen for them instead of following their age.
  final String? chosenCategoryId;

  /// Their club, if the event lists clubs.
  final String? organizationId;
  final String? organizationName;

  /// A minor on the day of the event whose guardian's agreement is not ticked.
  bool get needsGuardian => age < adultAge && !guardianConsent;
}

class StandingRow {
  const StandingRow({
    required this.position,
    required this.participantId,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.attendancePoints,
    required this.matchPoints,
    required this.total,
    required this.matches,
    this.categoryId,
    this.categoryName,
    this.teamNumber,
  });

  factory StandingRow.fromJson(Map<String, dynamic> json) => StandingRow(
    position: json['position'] as int,
    participantId: json['participantId'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    age: json['age'] as int,
    categoryId: json['categoryId'] as String?,
    categoryName: json['categoryName'] as String?,
    attendancePoints: json['attendancePoints'] as int,
    matchPoints: json['matchPoints'] as int,
    total: json['total'] as int,
    matches: json['matches'] as int,
    teamNumber: json['teamNumber'] as int?,
  );

  /// Equal totals share the position.
  final int position;
  final String participantId;
  final String firstName;
  final String lastName;
  final int age;
  final String? categoryId;
  final String? categoryName;
  final int attendancePoints;

  /// The participant's real team, or null.
  final int? teamNumber;
  final int matchPoints;
  final int total;
  final int matches;
}

class MatOverview {
  const MatOverview({
    required this.id,
    required this.number,
    required this.groups,
    required this.pendingMatches,
    required this.matchInProgress,
    required this.remaining,
    required this.estimatedEnd,
    this.referee,
    this.matchesInReview = 0,
  });

  factory MatOverview.fromJson(Map<String, dynamic> json) => MatOverview(
    id: json['id'] as String,
    number: json['number'] as int,
    referee: json['referee'] as String?,
    groups: json['groups'] as int,
    pendingMatches: json['pendingMatches'] as int,
    matchInProgress: json['matchInProgress'] as bool,
    remaining: Duration(seconds: json['remainingSeconds'] as int),
    estimatedEnd: DateTime.parse(json['estimatedEnd'] as String).toLocal(),
    matchesInReview: json['matchesInReview'] as int? ?? 0,
  );

  final String id;
  final int number;
  final String? referee;
  final int groups;
  final int pendingMatches;
  final bool matchInProgress;
  final Duration remaining;
  final DateTime estimatedEnd;

  /// Matches waiting for the club to apply or discard what a phone sent.
  final int matchesInReview;
}

/// What importing the hall's results brings. [alreadyImported]: the same results came before, nothing changes.
class ResultsImport {
  const ResultsImport({
    required this.alreadyImported,
    required this.newParticipants,
    required this.groups,
    required this.matches,
    required this.actions,
  });

  factory ResultsImport.fromJson(Map<String, dynamic> json) => ResultsImport(
    alreadyImported: json['alreadyImported'] as bool,
    newParticipants: json['newParticipants'] as int,
    groups: json['groups'] as int,
    matches: json['matches'] as int,
    actions: json['actions'] as int,
  );

  final bool alreadyImported;
  final int newParticipants;
  final int groups;
  final int matches;
  final int actions;
}

/// One participant's day: their standing row and every match they fight (with their team or as a
/// ghost too), as the club opens it.
class ParticipantRecord {
  const ParticipantRecord({required this.standing, required this.matches});

  factory ParticipantRecord.fromJson(Map<String, dynamic> json) =>
      ParticipantRecord(
        standing: StandingRow.fromJson(
          json['standing'] as Map<String, dynamic>,
        ),
        matches: [
          for (final m in json['matches'] as List)
            RecordMatch.fromJson(m as Map<String, dynamic>),
        ],
      );

  final StandingRow standing;
  final List<RecordMatch> matches;
}

enum IncidentKind { warning, oneHandWarning, disqualification }

/// A warning, one-hand warning or disqualification of a match: why, when on its clock and who.
/// [gaveRivalPoint]: a second warning that gave the rival a point.
class Incident {
  const Incident({
    required this.kind,
    required this.reason,
    required this.clock,
    this.by,
    this.gaveRivalPoint = false,
  });

  factory Incident.fromJson(Map<String, dynamic> json) => Incident(
    kind: switch (json['kind']) {
      'ONE_HAND_WARNING' => IncidentKind.oneHandWarning,
      'DISQUALIFICATION' => IncidentKind.disqualification,
      _ => IncidentKind.warning,
    },
    reason: json['reason'] as String? ?? '',
    clock: Duration(milliseconds: json['clockMs'] as int),
    by: json['by'] as String?,
    gaveRivalPoint: json['gaveRivalPoint'] as bool? ?? false,
  );

  final IncidentKind kind;
  final String reason;
  final Duration clock;
  final String? by;
  final bool gaveRivalPoint;

  bool get isWarning => kind != IncidentKind.disqualification;
}

/// One person across the league: each phase they entered, with its matches.
class LeagueRecord {
  const LeagueRecord(this.phases);

  factory LeagueRecord.fromJson(Map<String, dynamic> json) => LeagueRecord([
    for (final p in json['phases'] as List)
      (
        number: (p as Map<String, dynamic>)['number'] as int,
        name: p['name'] as String,
        matches: [
          for (final m in p['matches'] as List)
            RecordMatch.fromJson(m as Map<String, dynamic>),
        ],
      ),
  ]);

  final List<({int number, String name, List<RecordMatch> matches})> phases;
}

/// [red]: they fight in red. [asGhost]: they (or their team) only fill the group in.
class RecordMatch {
  const RecordMatch({
    required this.matchId,
    required this.matNumber,
    required this.groupNumber,
    required this.status,
    required this.red,
    required this.asGhost,
    this.team,
    required this.rival,
    required this.points,
    required this.rivalPoints,
    required this.warnings,
    required this.oneHandWarnings,
    required this.disqualified,
    required this.rivalDisqualified,
    this.endReason,
    this.incidents = const [],
  });

  factory RecordMatch.fromJson(Map<String, dynamic> json) => RecordMatch(
    matchId: json['matchId'] as String,
    matNumber: json['matNumber'] as int?,
    groupNumber: json['groupNumber'] as int,
    status: switch (json['status']) {
      'IN_PROGRESS' => MatchStatus.inProgress,
      'FINISHED' => MatchStatus.finished,
      _ => MatchStatus.pending,
    },
    red: json['side'] == 'RED',
    asGhost: json['asGhost'] as bool,
    team: json['team'] as int?,
    rival: json['rival'] as String,
    points: json['points'] as int,
    rivalPoints: json['rivalPoints'] as int,
    warnings: json['warnings'] as int,
    oneHandWarnings: json['oneHandWarnings'] as int,
    disqualified: json['disqualified'] as bool,
    rivalDisqualified: json['rivalDisqualified'] as bool,
    endReason: json['endReason'] as String?,
    incidents: [
      for (final i in json['incidents'] as List? ?? const [])
        Incident.fromJson(i as Map<String, dynamic>),
    ],
  );

  /// Their warnings and disqualification that stand, in order.
  final List<Incident> incidents;

  final String matchId;

  /// Null for a team match not started yet.
  final int? matNumber;
  final int groupNumber;
  final MatchStatus status;
  final bool red;
  final bool asGhost;
  final int? team;
  final String rival;
  final int points;
  final int rivalPoints;
  final int warnings;
  final int oneHandWarnings;
  final bool disqualified;
  final bool rivalDisqualified;
  final String? endReason;
}
