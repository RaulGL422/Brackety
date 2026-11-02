import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/state/session_controller.dart';
import 'club_models.dart';

final clubRepositoryProvider = Provider<ClubRepository>(
  (ref) => ClubRepository(ref.watch(apiProvider)),
);

enum CsvExport { standings, matches, timeline }

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
    required int maxGroupsPerMat,
    required List<String?> matReferees,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/v1/events/$eventId/settings',
      data: {
        'name': name,
        'date': _day.format(date),
        'maxGroupsPerMat': maxGroupsPerMat,
        'matReferees': matReferees,
      },
    );
    return EventSettings.fromJson(response.data!);
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
  }) async {
    final data = {
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': _day.format(birthDate),
      'heightCm': heightCm,
      'guardianConsent': guardianConsent,
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

  /// The file as the server sends it (UTF-8 with BOM, `;`-separated).
  Future<List<int>> csv(String eventId, CsvExport export) async {
    final response = await _dio.get<List<int>>(
      '/api/v1/events/$eventId/export/${export.name}.csv',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data!;
  }
}
