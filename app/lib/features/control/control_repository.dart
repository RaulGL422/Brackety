import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/state/session_controller.dart';

/// The club's control panel (server: MatchControlService): every change is checked there again.
class ControlRepository {
  ControlRepository(this._dio);

  final Dio _dio;

  String _base(String eventId) => '/api/v1/events/$eventId/control';

  Future<void> moveGroup(String eventId, String groupId, String matId) =>
      _dio.put<void>(
        '${_base(eventId)}/groups/$groupId/mat',
        data: {'matId': matId},
      );

  Future<void> moveMatch(String eventId, String matchId, String matId) =>
      _dio.put<void>(
        '${_base(eventId)}/matches/$matchId/mat',
        data: {'matId': matId},
      );

  /// [matchIds]: every pending match of the group, in the new order.
  Future<void> reorder(String eventId, String groupId, List<String> matchIds) =>
      _dio.put<void>(
        '${_base(eventId)}/groups/$groupId/order',
        data: {'matchIds': matchIds},
      );

  Future<void> moveTeamMember(
    String eventId, {
    required String participantId,
    required String fromTeamId,
    required String toTeamId,
  }) => _dio.post<void>(
    '${_base(eventId)}/team-members',
    data: {
      'participantId': participantId,
      'fromTeamId': fromTeamId,
      'toTeamId': toTeamId,
    },
  );

  /// The referee sends one of their mat's pending matches to another mat.
  Future<void> moveAsReferee(String matchId, String matId) =>
      _dio.post<void>('/api/v1/matches/$matchId/move', data: {'matId': matId});

  /// The mat goes out of use: its groups go to the mats free first, its pinned team matches to the pool.
  /// [groupMats]: group id → the mat chosen for it; the others go to the mat free first.
  Future<({int groupsMoved, int teamMatchesToPool})> disableMat(
    String eventId,
    String matId,
    Map<String, String> groupMats,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${_base(eventId)}/mats/$matId/disable',
      data: {'groupMats': groupMats},
    );
    final data = response.data!;
    return (
      groupsMoved: data['groupsMoved'] as int,
      teamMatchesToPool: data['teamMatchesToPool'] as int,
    );
  }

  Future<void> waiveRest(String eventId, String matchId) =>
      _dio.post<void>('${_base(eventId)}/matches/$matchId/waive-rest');
}

final controlRepositoryProvider = Provider<ControlRepository>(
  (ref) => ControlRepository(ref.watch(apiProvider)),
);
