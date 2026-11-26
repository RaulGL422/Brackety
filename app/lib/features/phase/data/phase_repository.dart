import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/session_controller.dart';
import '../../events/data/my_event.dart';

export '../../events/data/my_event.dart' show PhaseState;

/// A phase is started, played and finished (F1-7); finished, nobody changes it until the club reopens it.
class Phase {
  const Phase({required this.state, this.pendingMatches = 0});

  factory Phase.fromJson(Map<String, dynamic> json) => Phase(
    state: PhaseState.fromWire(json['state']),
    pendingMatches: json['pendingMatches'] as int? ?? 0,
  );

  final PhaseState state;

  /// What finishing now leaves unplayed.
  final int pendingMatches;
}

final phaseRepositoryProvider = Provider<PhaseRepository>(
  (ref) => PhaseRepository(ref.watch(apiProvider)),
);

final phaseProvider = FutureProvider.autoDispose.family<Phase, String>(
  (ref, eventId) => ref.watch(phaseRepositoryProvider).phase(eventId),
);

class PhaseRepository {
  PhaseRepository(this._dio);

  final Dio _dio;

  Future<Phase> phase(String eventId) => _get('/api/v1/events/$eventId/phase');

  Future<Phase> start(String eventId) => _post(eventId, 'start');

  Future<Phase> finish(String eventId) => _post(eventId, 'finish');

  Future<Phase> reopen(String eventId, String reason) =>
      _post(eventId, 'reopen', {'reason': reason});

  Future<Phase> _get(String path) async {
    final response = await _dio.get<Map<String, dynamic>>(path);
    return Phase.fromJson(response.data!);
  }

  Future<Phase> _post(String eventId, String action, [Object? body]) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/events/$eventId/phase/$action',
      data: body,
    );
    return Phase.fromJson(response.data!);
  }
}
