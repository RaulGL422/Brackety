import 'package:dio/dio.dart';

enum AdminMatchStatus { pending, inProgress, finished }

/// A team member; [ghost]: fills the team in but does not score for it.
class AdminMember {
  const AdminMember({required this.name, this.ghost = false});

  factory AdminMember.fromJson(Map<String, dynamic> json) => AdminMember(
    name: json['name'] as String,
    ghost: json['ghost'] as bool? ?? false,
  );

  final String name;
  final bool ghost;
}

/// A participant's name, or a team ([teamNumber], no name) with its [members]. [ghost]: fights in
/// the group but does not score.
class AdminSide {
  const AdminSide({
    this.name,
    this.teamNumber,
    this.ghost = false,
    this.members = const [],
  });

  factory AdminSide.fromJson(Map<String, dynamic> json) => AdminSide(
    name: json['name'] as String?,
    teamNumber: json['teamNumber'] as int?,
    ghost: json['ghost'] as bool? ?? false,
    members: [
      for (final m in json['members'] as List? ?? const [])
        AdminMember.fromJson(m as Map<String, dynamic>),
    ],
  );

  final String? name;
  final int? teamNumber;
  final bool ghost;
  final List<AdminMember> members;
}

/// A pending match in the order the mat's referee would be offered it.
class AdminPlannedMatch {
  const AdminPlannedMatch({
    required this.matchId,
    required this.groupNumber,
    required this.category,
    required this.startsAt,
    required this.red,
    required this.blue,
  });

  factory AdminPlannedMatch.fromJson(Map<String, dynamic> json) =>
      AdminPlannedMatch(
        matchId: json['matchId'] as String,
        groupNumber: json['groupNumber'] as int,
        category: json['category'] as String,
        startsAt: DateTime.parse(json['startsAt'] as String).toLocal(),
        red: AdminSide.fromJson(json['red'] as Map<String, dynamic>),
        blue: AdminSide.fromJson(json['blue'] as Map<String, dynamic>),
      );

  final String matchId;
  final int groupNumber;
  final String category;

  /// Estimated: every match at its full time plus the changeover.
  final DateTime startsAt;
  final AdminSide red;
  final AdminSide blue;
}

class AdminMatch {
  const AdminMatch({
    required this.id,
    required this.order,
    required this.status,
    required this.red,
    required this.blue,
    required this.redScore,
    required this.blueScore,
    required this.inReview,
  });

  factory AdminMatch.fromJson(Map<String, dynamic> json) => AdminMatch(
    id: json['id'] as String,
    order: json['order'] as int,
    status: switch (json['status']) {
      'IN_PROGRESS' => AdminMatchStatus.inProgress,
      'FINISHED' => AdminMatchStatus.finished,
      _ => AdminMatchStatus.pending,
    },
    red: AdminSide.fromJson(json['red'] as Map<String, dynamic>),
    blue: AdminSide.fromJson(json['blue'] as Map<String, dynamic>),
    redScore: json['redScore'] as int,
    blueScore: json['blueScore'] as int,
    inReview: json['inReview'] as bool,
  );

  final String id;
  final int order;
  final AdminMatchStatus status;
  final AdminSide red;
  final AdminSide blue;
  final int redScore;
  final int blueScore;
  final bool inReview;

  /// A pending match without a review has nothing to restart.
  bool get canReset => status != AdminMatchStatus.pending || inReview;
}

class AdminGroup {
  const AdminGroup({
    required this.id,
    required this.number,
    required this.category,
    required this.matNumber,
    this.createdBy,
    this.members = const [],
    required this.matches,
  });

  factory AdminGroup.fromJson(Map<String, dynamic> json) => AdminGroup(
    id: json['id'] as String,
    number: json['number'] as int,
    category: json['category'] as String,
    matNumber: json['matNumber'] as int?,
    createdBy: json['createdBy'] as String?,
    members: [
      for (final m in json['members'] as List? ?? const [])
        AdminSide.fromJson(m as Map<String, dynamic>),
    ],
    matches: [
      for (final m in json['matches'] as List)
        AdminMatch.fromJson(m as Map<String, dynamic>),
    ],
  );

  final String id;
  final int number;
  final String category;

  /// Null for a group of teams: its matches go to the free mats.
  final int? matNumber;

  /// Who made it ("Ana López (ayudante1)", or the sign-in alone).
  final String? createdBy;

  /// In group order, the ghost included.
  final List<AdminSide> members;
  final List<AdminMatch> matches;
}

class AdminMat {
  const AdminMat({
    required this.id,
    required this.number,
    this.referee,
    this.plan = const [],
  });

  factory AdminMat.fromJson(Map<String, dynamic> json) => AdminMat(
    id: json['id'] as String,
    number: json['number'] as int,
    referee: json['referee'] as String?,
    plan: [
      for (final p in json['plan'] as List? ?? const [])
        AdminPlannedMatch.fromJson(p as Map<String, dynamic>),
    ],
  );

  final String id;
  final int number;

  /// The referee's sign-in; null when the mat has none.
  final String? referee;

  /// Its pending matches in the order they would come up if all goes as planned.
  final List<AdminPlannedMatch> plan;
}

class AdminEventRow {
  const AdminEventRow({
    required this.id,
    required this.name,
    required this.date,
    required this.ownerEmail,
    required this.mats,
    required this.entries,
    required this.groups,
    required this.matchesFinished,
    required this.matches,
  });

  factory AdminEventRow.fromJson(Map<String, dynamic> json) => AdminEventRow(
    id: json['id'] as String,
    name: json['name'] as String,
    date: DateTime.parse(json['date'] as String),
    ownerEmail: json['ownerEmail'] as String,
    mats: json['mats'] as int,
    entries: json['entries'] as int,
    groups: json['groups'] as int,
    matchesFinished: json['matchesFinished'] as int,
    matches: json['matches'] as int,
  );

  final String id;
  final String name;
  final DateTime date;
  final String ownerEmail;
  final int mats;
  final int entries;
  final int groups;
  final int matchesFinished;
  final int matches;
}

class AdminEventPage {
  const AdminEventPage({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
  });

  factory AdminEventPage.fromJson(Map<String, dynamic> json) => AdminEventPage(
    items: [
      for (final e in json['items'] as List)
        AdminEventRow.fromJson(e as Map<String, dynamic>),
    ],
    page: json['page'] as int,
    size: json['size'] as int,
    total: json['total'] as int,
  );

  final List<AdminEventRow> items;
  final int page;
  final int size;
  final int total;

  int get pageCount => total == 0 ? 1 : (total + size - 1) ~/ size;
  bool get hasNext => page + 1 < pageCount;
}

/// A person of a real team; [ghost]: fills it in without scoring.
class AdminTeamPerson {
  const AdminTeamPerson({
    required this.participantId,
    required this.name,
    this.ghost = false,
  });

  factory AdminTeamPerson.fromJson(Map<String, dynamic> json) =>
      AdminTeamPerson(
        participantId: json['participantId'] as String,
        name: json['name'] as String,
        ghost: json['ghost'] as bool? ?? false,
      );

  final String participantId;
  final String name;
  final bool ghost;
}

/// A real team: who is in it and the group it fights in, for the control panel.
class AdminTeam {
  const AdminTeam({
    required this.id,
    required this.number,
    required this.category,
    required this.members,
    this.groupNumber,
    this.groupStarted = false,
  });

  factory AdminTeam.fromJson(Map<String, dynamic> json) => AdminTeam(
    id: json['id'] as String,
    number: json['number'] as int,
    category: json['category'] as String,
    groupNumber: json['groupNumber'] as int?,
    groupStarted: json['groupStarted'] as bool? ?? false,
    members: [
      for (final m in json['members'] as List)
        AdminTeamPerson.fromJson(m as Map<String, dynamic>),
    ],
  );

  final String id;
  final int number;
  final String category;
  final int? groupNumber;

  /// Its group has started: its people no longer change.
  final bool groupStarted;
  final List<AdminTeamPerson> members;
}

class AdminEventDetail {
  const AdminEventDetail({
    required this.id,
    required this.name,
    required this.date,
    required this.ownerEmail,
    required this.entries,
    required this.mats,
    required this.groups,
    this.teams = const [],
  });

  factory AdminEventDetail.fromJson(Map<String, dynamic> json) =>
      AdminEventDetail(
        id: json['id'] as String,
        name: json['name'] as String,
        date: DateTime.parse(json['date'] as String),
        ownerEmail: json['ownerEmail'] as String,
        entries: json['entries'] as int,
        mats: [
          for (final m in json['mats'] as List)
            AdminMat.fromJson(m as Map<String, dynamic>),
        ],
        groups: [
          for (final g in json['groups'] as List)
            AdminGroup.fromJson(g as Map<String, dynamic>),
        ],
        teams: [
          for (final t in json['teams'] as List? ?? const [])
            AdminTeam.fromJson(t as Map<String, dynamic>),
        ],
      );

  final String id;
  final String name;
  final DateTime date;
  final String ownerEmail;
  final int entries;
  final List<AdminMat> mats;
  final List<AdminGroup> groups;
  final List<AdminTeam> teams;
}

/// What clearing the competition took: groups and teams (ghost teams included).
typedef Cleared = ({int groups, int teams});

/// The superadmin's view of events and what it can undo in them (every call is audited).
class EventsApi {
  EventsApi(this._dio);

  final Dio _dio;

  static const _base = '/api/v1/admin';

  Future<AdminEventPage> list({required int page, int size = 20}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/events',
      queryParameters: {'page': page, 'size': size},
    );
    return AdminEventPage.fromJson(response.data!);
  }

  Future<AdminEventDetail> detail(String eventId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_base/events/$eventId',
    );
    return AdminEventDetail.fromJson(response.data!);
  }

  Future<void> resetMatch(String matchId, String reason) => _dio.post<void>(
    '$_base/matches/$matchId/reset',
    data: {'reason': reason},
  );

  Future<void> dissolveGroup(String groupId, String reason) => _dio.post<void>(
    '$_base/groups/$groupId/dissolve',
    data: {'reason': reason},
  );

  String _control(String eventId) => '$_base/events/$eventId/control';

  Future<void> moveGroup(String eventId, String groupId, String matId) =>
      _dio.put<void>(
        '${_control(eventId)}/groups/$groupId/mat',
        data: {'matId': matId},
      );

  Future<void> moveMatch(String eventId, String matchId, String matId) =>
      _dio.put<void>(
        '${_control(eventId)}/matches/$matchId/mat',
        data: {'matId': matId},
      );

  Future<void> reorder(String eventId, String groupId, List<String> matchIds) =>
      _dio.put<void>(
        '${_control(eventId)}/groups/$groupId/order',
        data: {'matchIds': matchIds},
      );

  Future<void> moveTeamMember(
    String eventId, {
    required String participantId,
    required String fromTeamId,
    required String toTeamId,
  }) => _dio.post<void>(
    '${_control(eventId)}/team-members',
    data: {
      'participantId': participantId,
      'fromTeamId': fromTeamId,
      'toTeamId': toTeamId,
    },
  );

  Future<void> waiveRest(String eventId, String matchId) =>
      _dio.post<void>('${_control(eventId)}/matches/$matchId/waive-rest');

  Future<Cleared> clearCompetition(String eventId, String reason) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/events/$eventId/clear-competition',
      data: {'reason': reason},
    );
    final body = response.data!;
    return (groups: body['groups'] as int, teams: body['teams'] as int);
  }
}
