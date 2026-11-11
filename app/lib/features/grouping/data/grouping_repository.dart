import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/session_controller.dart';
import '../state/group_draft.dart';
import 'grouping_models.dart';

final groupingRepositoryProvider = Provider<GroupingRepository>(
  (ref) => GroupingRepository(ref.watch(apiProvider)),
);

class GroupingRepository {
  GroupingRepository(this._dio);

  final Dio _dio;

  Future<List<CategorySummary>> categories(String eventId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/events/$eventId/categories',
    );
    return [
      for (final json in response.data!)
        CategorySummary.fromJson(json as Map<String, dynamic>),
    ];
  }

  Future<List<CategoryParticipant>> participants(
    String eventId,
    String categoryId,
  ) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/events/$eventId/categories/$categoryId/participants',
    );
    return [
      for (final json in response.data!)
        CategoryParticipant.fromJson(json as Map<String, dynamic>),
    ];
  }

  /// Without [matId] the server picks the mat that will be free first.
  Future<CreatedGroups> create(
    String eventId,
    String categoryId,
    DraftGroup group, {
    String? matId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/events/$eventId/groups',
      data: {
        'categoryId': categoryId,
        'groups': [
          group.ofTeams
              ? {
                  'teamIds': group.members,
                  if (group.ghostMode) 'ghostTeam': group.ghostTeam,
                }
              : {'participantIds': group.members, 'ghostId': group.ghost},
        ],
        'matId': ?matId,
      },
    );
    return CreatedGroups.fromJson(response.data!);
  }

  Future<List<Team>> teams(String eventId, String categoryId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/events/$eventId/categories/$categoryId/teams',
    );
    return [
      for (final json in response.data!)
        Team.fromJson(json as Map<String, dynamic>),
    ];
  }

  Future<Team> createTeam(
    String eventId,
    String categoryId,
    List<String> participantIds,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/events/$eventId/categories/$categoryId/teams',
      data: {'participantIds': participantIds},
    );
    return Team.fromJson(response.data!);
  }

  /// 409 once a match of the group has started.
  Future<void> undoGroup(String eventId, String groupId) =>
      _dio.delete<void>('/api/v1/events/$eventId/groups/$groupId');

  Future<void> deleteTeam(String eventId, String teamId) =>
      _dio.delete<void>('/api/v1/events/$eventId/teams/$teamId');
}
