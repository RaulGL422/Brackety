import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/state/session_controller.dart';
import 'club_models.dart';

final clubRepositoryProvider = Provider<ClubRepository>(
  (ref) => ClubRepository(ref.watch(apiProvider)),
);

/// What the club can download: CSVs for Excel and the whole event as a .zip (every CSV, a LEEME.txt and the
/// package that loads the sports hall server or brings its results back).
enum EventExport {
  standings('export/standings.csv', 'clasificacion.csv', 'text/csv'),
  participants('export/participants.csv', 'inscritos.csv', 'text/csv'),
  matches('export/matches.csv', 'combates.csv', 'text/csv'),
  timeline('export/timeline.csv', 'linea-de-tiempo.csv', 'text/csv'),
  leagueStandings(
    'export/league-standings.csv',
    'clasificacion-liga.csv',
    'text/csv',
  ),
  full('export/full', 'evento.zip', 'application/zip');

  const EventExport(this.path, this.fallbackName, this.mimeType);

  final String path;

  /// Only if the server's Content-Disposition does not reach the app.
  final String fallbackName;
  final String mimeType;
}

class ClubRepository {
  ClubRepository(this._dio);

  final Dio _dio;

  static final _day = DateFormat('yyyy-MM-dd');

  Future<EventSettings> settings(String eventId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/events/$eventId/settings',
    );
    return EventSettings.fromJson(response.data!);
  }

  Future<EventSettings> saveSettings(
    String eventId, {
    required String name,
    required DateTime date,
    required List<String?> matReferees,
    required Duration matchLength,
    required int pointsLimit,
    required int attendancePoints,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/v1/events/$eventId/settings',
      data: {
        'name': name,
        'date': _day.format(date),
        // No multigroup any more (docs/decisiones.md, 2026-11-07); the server still asks for it.
        'maxGroupsPerMat': 1,
        'matReferees': matReferees,
        'matchSeconds': matchLength.inSeconds,
        'pointsLimit': pointsLimit,
        'attendancePoints': attendancePoints,
      },
    );
    return EventSettings.fromJson(response.data!);
  }

  /// The person behind a staff account in this event; blank removes it.
  Future<void> saveStaffName(String eventId, String accountId, String name) =>
      _dio.put<void>(
        '/api/v1/events/$eventId/staff/$accountId/name',
        data: {'name': name},
      );

  /// The event's whole category list: those left out are removed.
  Future<List<EventCategory>> saveCategories(
    String eventId,
    List<EventCategory> categories,
  ) async {
    final response = await _dio.put<List<dynamic>>(
      '/api/v1/events/$eventId/categories',
      data: {
        'categories': [for (final c in categories) c.toJson()],
      },
    );
    return [
      for (final c in response.data!)
        EventCategory.fromJson(c as Map<String, dynamic>),
    ];
  }

  /// The whole list: clubs left out are removed (409 if one still has participants).
  Future<List<Organization>> saveOrganizations(
    String eventId,
    List<Organization> organizations,
  ) async {
    final response = await _dio.put<List<dynamic>>(
      '/api/v1/events/$eventId/organizations',
      data: {
        'organizations': [for (final o in organizations) o.toJson()],
      },
    );
    return [
      for (final o in response.data!)
        Organization.fromJson(o as Map<String, dynamic>),
    ];
  }

  Future<List<Participant>> participants(String eventId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/events/$eventId/participants',
    );
    return [
      for (final json in response.data!)
        Participant.fromJson(json as Map<String, dynamic>),
    ];
  }

  /// Creates the participant, or updates it when [participantId] is given.
  Future<void> saveParticipant(
    String eventId, {
    String? participantId,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    required int? heightCm,
    required bool guardianConsent,
    String? categoryId,
    String? organizationId,
  }) async {
    final data = {
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': _day.format(birthDate),
      'heightCm': heightCm,
      'guardianConsent': guardianConsent,
      'categoryId': categoryId,
      'organizationId': organizationId,
    };
    final path = '/api/v1/events/$eventId/participants';
    if (participantId == null) {
      await _dio.post<void>(path, data: data);
    } else {
      await _dio.put<void>('$path/$participantId', data: data);
    }
  }

  Future<void> deleteParticipant(String eventId, String participantId) =>
      _dio.delete<void>('/api/v1/events/$eventId/participants/$participantId');

  Future<List<StandingRow>> standings(String eventId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/events/$eventId/standings',
    );
    return [
      for (final json in response.data!)
        StandingRow.fromJson(json as Map<String, dynamic>),
    ];
  }

  Future<List<MatOverview>> mats(String eventId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/events/$eventId/mats',
    );
    return [
      for (final json in response.data!)
        MatOverview.fromJson(json as Map<String, dynamic>),
    ];
  }

  /// The hall's results (its full export) into this event. [dryRun] only counts what would come in.
  Future<ResultsImport> importResults(
    String eventId,
    List<int> file, {
    required bool dryRun,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/events/$eventId/import/results',
      queryParameters: {'dryRun': dryRun},
      data: Stream.value(file),
      options: Options(
        contentType: 'application/octet-stream',
        headers: {Headers.contentLengthHeader: file.length},
      ),
    );
    return ResultsImport.fromJson(response.data!);
  }

  /// The file as the server sends it (CSVs: UTF-8 with BOM, `;`-separated), with the name it gives.
  Future<({String name, List<int> bytes})> export(
    String eventId,
    EventExport export,
  ) async {
    final response = await _dio.get<List<int>>(
      '/api/v1/events/$eventId/${export.path}',
      options: Options(responseType: ResponseType.bytes),
    );
    final disposition = response.headers.value('content-disposition') ?? '';
    final name = RegExp(r'filename="([^"]+)"')
        .firstMatch(disposition)
        ?.group(1);
    return (name: name ?? export.fallbackName, bytes: response.data!);
  }
}
