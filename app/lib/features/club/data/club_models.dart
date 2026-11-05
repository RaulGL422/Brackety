class StaffMember {
  const StaffMember({required this.id, required this.username});

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
    id: json['id'] as String,
    username: json['username'] as String,
  );

  final String id;
  final String username;
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
    required this.maxGroupsPerMat,
    required this.matReferees,
    required this.referees,
    required this.categories,
  });

  factory EventSettings.fromJson(Map<String, dynamic> json) {
    final mats = [
      for (final m in json['mats'] as List) m as Map<String, dynamic>,
    ]..sort((a, b) => (a['number'] as int).compareTo(b['number'] as int));
    return EventSettings(
      name: json['name'] as String,
      date: DateTime.parse(json['date'] as String),
      maxGroupsPerMat: json['maxGroupsPerMat'] as int,
      matReferees: [for (final m in mats) m['refereeId'] as String?],
      referees: [
        for (final r in json['referees'] as List)
          StaffMember.fromJson(r as Map<String, dynamic>),
      ],
      categories: [
        for (final c in json['categories'] as List)
          EventCategory.fromJson(c as Map<String, dynamic>),
      ],
    );
  }

  final String name;
  final DateTime date;
  final int maxGroupsPerMat;

  /// One entry per mat, mat 1 first: the referee's account id, or null.
  final List<String?> matReferees;

  /// Accounts that can referee a mat in this event.
  final List<StaffMember> referees;
  final List<EventCategory> categories;
}

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
