import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/state/session_controller.dart';
import 'league_models.dart';

final leagueRepositoryProvider = Provider<LeagueRepository>(
  (ref) => LeagueRepository(ref.watch(apiProvider)),
);

/// The league an event is a phase of; every call goes through one of its phases (docs/modulos/liga-fases.md).
class LeagueRepository {
  LeagueRepository(this._dio);

  final Dio _dio;

  String _path(String eventId) => '/api/v1/events/$eventId/league';

  Future<League> league(String eventId) async {
    final response = await _dio.get<Map<String, dynamic>>(_path(eventId));
    return League.fromJson(response.data!);
  }

  Future<League> save(
    String eventId, {
    required String name,
    required Podium podium,
    required List<CategoryPodium> categoryPodiums,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      _path(eventId),
      data: {
        'name': name,
        'podium': podium.toJson(),
        'categoryPodiums': [for (final c in categoryPodiums) c.toJson()],
      },
    );
    return League.fromJson(response.data!);
  }

  /// The next phase, copying mats with their referees, staff, categories and clubs from [eventId].
  Future<LeaguePhase> createPhase(
    String eventId, {
    required String name,
    required DateTime date,
    required Discipline discipline,
    required int attendancePoints,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${_path(eventId)}/phases',
      data: {
        'name': name,
        'date': DateFormat('yyyy-MM-dd').format(date),
        'discipline': disciplineJson(discipline),
        'attendancePoints': attendancePoints,
      },
    );
    return LeaguePhase.fromJson(response.data!);
  }

  Future<List<LeagueCandidate>> candidates(String eventId) async {
    final response = await _dio.get<List<dynamic>>(
      '${_path(eventId)}/candidates',
    );
    return [
      for (final c in response.data!)
        LeagueCandidate.fromJson(c as Map<String, dynamic>),
    ];
  }

  /// Returns how many were entered.
  Future<int> reenrol(
    String eventId,
    List<String> personIds, {
    required bool guardianConsent,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${_path(eventId)}/reenrol',
      data: {'personIds': personIds, 'guardianConsent': guardianConsent},
    );
    return response.data!['added'] as int;
  }

  Future<LeagueStandings> standings(String eventId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${_path(eventId)}/standings',
    );
    return LeagueStandings.fromJson(response.data!);
  }
}
