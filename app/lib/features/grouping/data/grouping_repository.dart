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

  /// Without [matId] the server picks the mat that will be free first; a group of teams has no
  /// mat (its matches go to the free mats).
  Future<CreatedGroups> create(
    String eventId,
    String categoryId,
    DraftGroup group, {
    String? matId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      groupsPath(eventId),
      data: groupBody(categoryId, group, matId: matId),
    );
    return CreatedGroups.fromJson(response.data!);
  }

  static String groupsPath(String eventId) => '/api/v1/events/$eventId/groups';

  static Map<String, dynamic> groupBody(
    String categoryId,
    DraftGroup group, {
    String? matId,
  }) => {
    'categoryId': categoryId,
    'groups': [
      group.ofTeams
          ? {
              'teamIds': group.members,
              if (group.ghostMode) 'ghostTeams': group.ghostTeams,
            }
          : {'participantIds': group.members, 'ghostIds': group.ghosts},
    ],
    if (!group.ofTeams) 'matId': ?matId,
  };

  static String teamsPath(String eventId, String categoryId) =>
      '/api/v1/events/$eventId/categories/$categoryId/teams';

  Future<List<Team>> teams(String eventId, String categoryId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/events/$eventId/categories/$categoryId/teams',
    );
    return [
      for (final json in response.data!)
        Team.fromJson(json as Map<String, dynamic>),
    ];
  }

  /// [ghostIds]: those of [participantIds] who fill the team in without scoring for it.
  Future<Team> createTeam(
    String eventId,
    String categoryId,
    List<String> participantIds, {
    List<String> ghostIds = const [],
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      teamsPath(eventId, categoryId),
      data: {'participantIds': participantIds, 'ghostIds': ghostIds},
    );
    return Team.fromJson(response.data!);
  }

  /// 409 once a match of the group has started.
  Future<void> undoGroup(String eventId, String groupId) =>
      _dio.delete<void>('/api/v1/events/$eventId/groups/$groupId');

  Future<void> deleteTeam(String eventId, String teamId) =>
      _dio.delete<void>('/api/v1/events/$eventId/teams/$teamId');
}
