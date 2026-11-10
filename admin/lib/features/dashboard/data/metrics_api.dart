import 'package:dio/dio.dart';

/// The superadmin's counts, read at [at] (GET /api/v1/admin/metrics).
class AdminMetrics {
  const AdminMetrics({
    required this.at,
    required this.activeAccounts,
    required this.unverified,
    required this.newLast7Days,
    required this.pendingDeletion,
    required this.organizersPending,
    required this.activeSessions,
    required this.activeLocks,
    required this.byProfile,
    required this.events,
    required this.upcomingEvents,
    required this.entries,
    required this.importsLast7Days,
    required this.importedLast7Days,
    required this.matchesFinished24h,
    required this.scoreboardActions24h,
    required this.groupsCreated24h,
    required this.matchesInProgress,
    required this.matchesInReview,
    required this.startedAt,
    required this.serverErrors,
  });

  factory AdminMetrics.fromJson(Map<String, dynamic> json) {
    final users = json['users'] as Map<String, dynamic>;
    final events = json['events'] as Map<String, dynamic>;
    final activity = json['activity'] as Map<String, dynamic>;
    final server = json['server'] as Map<String, dynamic>;
    return AdminMetrics(
      at: DateTime.parse(json['at'] as String),
      activeAccounts: users['active'] as int,
      unverified: users['unverified'] as int,
      newLast7Days: users['newLast7Days'] as int,
      pendingDeletion: users['pendingDeletion'] as int,
      organizersPending: users['organizersPending'] as int,
      activeSessions: users['activeSessions'] as int,
      activeLocks: users['activeLocks'] as int,
      byProfile: {
        for (final MapEntry(:key, :value)
            in (users['byProfile'] as Map<String, dynamic>).entries)
          key: value as int,
      },
      events: events['total'] as int,
      upcomingEvents: events['upcoming'] as int,
      entries: events['entries'] as int,
      importsLast7Days: events['importsLast7Days'] as int,
      importedLast7Days: events['importedLast7Days'] as int,
      matchesFinished24h: activity['matchesFinished24h'] as int,
      scoreboardActions24h: activity['scoreboardActions24h'] as int,
      groupsCreated24h: activity['groupsCreated24h'] as int,
      matchesInProgress: activity['matchesInProgress'] as int,
      matchesInReview: activity['matchesInReview'] as int,
      startedAt: DateTime.parse(server['startedAt'] as String),
      serverErrors: server['serverErrors'] as int,
    );
  }

  final DateTime at;
  final int activeAccounts;
  final int unverified;
  final int newLast7Days;
  final int pendingDeletion;
  final int organizersPending;
  final int activeSessions;
  final int activeLocks;

  /// Active accounts with each profile (CLUB, EXTERNAL_ENTITY, HELPER, STUDENT, EXTERNAL).
  final Map<String, int> byProfile;
  final int events;
  final int upcomingEvents;
  final int entries;
  final int importsLast7Days;
  final int importedLast7Days;
  final int matchesFinished24h;
  final int scoreboardActions24h;
  final int groupsCreated24h;
  final int matchesInProgress;
  final int matchesInReview;

  /// The API's last start: [serverErrors] counts the 5xx answers since then.
  final DateTime startedAt;
  final int serverErrors;
}

class MetricsApi {
  MetricsApi(this._dio);

  final Dio _dio;

  Future<AdminMetrics> read() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/admin/metrics',
    );
    return AdminMetrics.fromJson(response.data!);
  }
}
