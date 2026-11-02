import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/session_controller.dart';
import 'match_view.dart';

final scoreboardRepositoryProvider = Provider<ScoreboardRepository>(
  (ref) => ScoreboardRepository(ref.watch(apiProvider)),
);

class ScoreboardRepository {
  ScoreboardRepository(this._dio);

  final Dio _dio;

  Future<MatchView> load(String matchId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/matches/$matchId',
    );
    return MatchView.fromJson(response.data!);
  }

  Future<MatchView> send(
    String matchId,
    MatchAction action, {
    Side? side,
    String? reason,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/matches/$matchId/events',
      data: {
        'type': action.wire,
        'side': side?.name.toUpperCase(),
        'reason': reason,
      },
    );
    return MatchView.fromJson(response.data!);
  }
}
