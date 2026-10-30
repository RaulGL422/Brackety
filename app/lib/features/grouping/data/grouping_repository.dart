import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../session/state/session_controller.dart';
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

  Future<CreatedGroups> create(
    String eventId,
    String categoryId,
    List<DraftGroup> groups,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/events/$eventId/groups',
      data: {
        'categoryId': categoryId,
        'groups': [
          for (final g in groups)
            {'participantIds': g.members, 'ghostId': g.ghost},
        ],
      },
    );
    return CreatedGroups.fromJson(response.data!);
  }
}
