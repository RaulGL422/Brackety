import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/session_controller.dart';
import '../../offline/data/offline_op.dart';
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
      data: {'type': action.wire, 'side': sideToJson(side), 'reason': reason},
    );
    return MatchView.fromJson(response.data!);
  }

  /// An action from the Android queue: applied once, at its own time ([OfflineOp.toRequest]).
  Future<MatchView> sendOp(OfflineOp op) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/matches/${op.matchId}/events',
      data: op.toRequest(),
    );
    return MatchView.fromJson(response.data!);
  }

  /// The club applies or discards the actions a device sent that clashed.
  Future<ReviewOutcome> review(String matchId, ReviewDecision decision) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/matches/$matchId/review',
      data: {'action': decision.name.toUpperCase()},
    );
    return ReviewOutcome.fromJson(response.data!);
  }
}
