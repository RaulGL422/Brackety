import 'package:dio/dio.dart';

enum AdminMatchStatus { pending, inProgress, finished }

/// A participant's name, or a team ([teamNumber], no name).
class AdminSide {
  const AdminSide({this.name, this.teamNumber});

  factory AdminSide.fromJson(Map<String, dynamic> json) => AdminSide(
    name: json['name'] as String?,
    teamNumber: json['teamNumber'] as int?,
  );

  final String? name;
  final int? teamNumber;
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
    required this.matches,
  });

  factory AdminGroup.fromJson(Map<String, dynamic> json) => AdminGroup(
    id: json['id'] as String,
    number: json['number'] as int,
    category: json['category'] as String,
    matNumber: json['matNumber'] as int,
    matches: [
      for (final m in json['matches'] as List)
        AdminMatch.fromJson(m as Map<String, dynamic>),
    ],
  );

  final String id;
  final int number;
  final String category;
  final int matNumber;
  final List<AdminMatch> matches;
}

class AdminMat {
  const AdminMat({required this.id, required this.number, this.referee});

  factory AdminMat.fromJson(Map<String, dynamic> json) => AdminMat(
    id: json['id'] as String,
    number: json['number'] as int,
    referee: json['referee'] as String?,
  );

  final String id;
  final int number;

  /// The referee's sign-in; null when the mat has none.
  final String? referee;
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

class AdminEventDetail {
  const AdminEventDetail({
    required this.id,
    required this.name,
    required this.date,
    required this.ownerEmail,
    required this.entries,
    required this.mats,
    required this.groups,
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
      );

  final String id;
  final String name;
  final DateTime date;
  final String ownerEmail;
  final int entries;
  final List<AdminMat> mats;
  final List<AdminGroup> groups;
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

  Future<Cleared> clearCompetition(String eventId, String reason) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/events/$eventId/clear-competition',
      data: {'reason': reason},
    );
    final body = response.data!;
    return (groups: body['groups'] as int, teams: body['teams'] as int);
  }
}
