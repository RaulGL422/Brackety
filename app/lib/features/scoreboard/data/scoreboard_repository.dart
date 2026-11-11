import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/session_controller.dart';
import '../../offline/data/offline_op.dart';
import 'match_view.dart';

final scoreboardRepositoryProvider = Provider<ScoreboardRepository>(
  (ref) => ScoreboardRepository(ref.watch(apiProvider)),
);

/// What an import did: new, already on the server, sent to review, refused.
typedef OfflineImportResult = ({
  int applied,
  int duplicates,
  int inReview,
  int skipped,
});

class ScoreboardRepository {
  ScoreboardRepository(this._dio);

  final Dio _dio;

  Future<MatchView> load(String matchId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/matches/$matchId',
    );
    return MatchView.fromJson(response.data!);
  }

  /// An action from the device's queue: applied once, at its own time ([OfflineOp.toRequest]).
  Future<MatchView> sendOp(OfflineOp op) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/matches/${op.matchId}/events',
      data: op.toRequest(),
    );
    return MatchView.fromJson(response.data!);
  }

  /// The club imports the CSV a device exported with the actions it could not send.
  Future<OfflineImportResult> importOps(String eventId, List<int> csv) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/events/$eventId/offline-ops/import',
      data: utf8.decode(csv, allowMalformed: true),
      options: Options(contentType: 'text/csv; charset=utf-8'),
    );
    final json = response.data!;
    return (
      applied: json['applied'] as int,
      duplicates: json['duplicates'] as int,
      inReview: json['inReview'] as int,
      skipped: json['skipped'] as int,
    );
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
