import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/polling.dart';
import '../../auth/data/api_error.dart';
import '../../auth/state/session_controller.dart';
import '../../offline/data/local_board.dart';
import '../../offline/state/offline_sync.dart';
import '../../scoreboard/data/match_view.dart';
import '../data/mat_board.dart';

/// The board follows its mat on the live socket: matches on other mats change what is
/// available here too, so the server signals it for any change in the event.
Set<String> boardTopics(String matId) => {'mat:$matId'};

final matBoardProvider = FutureProvider.autoDispose.family<MatBoard, String>(
  (ref, matId) => liveReload(ref, boardTopics(matId), () => _board(ref, matId)),
);

/// The referee's board: from the server, kept on the device, and from there when the server
/// does not answer ([MatBoard.offline]).
final cachedBoardProvider = FutureProvider.autoDispose.family<MatBoard, String>(
  (ref, matId) =>
      liveReload(ref, boardTopics(matId), () => _cachedBoard(ref, matId)),
);

Future<MatBoard> _board(Ref ref, String matId) async {
  final response = await ref
      .watch(apiProvider)
      .get<Map<String, dynamic>>('/api/v1/mats/$matId/board');
  return MatBoard.fromJson(response.data!);
}

Future<MatBoard> _cachedBoard(Ref ref, String matId) async {
  final sync = ref.read(offlineSyncProvider.notifier);
  // Known to be offline: the saved board at once, not after a timeout. When the background
  // check finds the server again, this runs again and fetches it.
  if (!ref.watch(offlineSyncProvider.select((s) => s.connected))) {
    final cached = await sync.cachedBoard(matId);
    if (cached is Map<String, dynamic>) return _offlineBoard(cached);
  }
  try {
    final response = await ref
        .watch(apiProvider)
        .get<Map<String, dynamic>>('/api/v1/mats/$matId/board');
    sync.reportResponse();
    final board = MatBoard.fromJson(response.data!);
    unawaited(sync.saveBoard(matId, response.data));
    unawaited(sync.syncBoard(board));
    return board;
  } on DioException catch (e) {
    if (!ApiError.from(e).noResponse) rethrow;
    sync.reportNoResponse();
    final cached = await sync.cachedBoard(matId);
    if (cached is! Map<String, dynamic>) rethrow;
    return _offlineBoard(cached);
  }
}

// The last proposal stays: offline only that one of the team pool can start here.
MatBoard _offlineBoard(Map<String, dynamic> cached) {
  final board = MatBoard.fromJson(cached);
  return MatBoard(
    matNumber: board.matNumber,
    groups: board.groups,
    matches: board.matches,
    recommendedMatchId: board.recommendedMatchId,
    offline: true,
    teamPool: board.teamPool,
    eventId: board.eventId,
    mats: board.mats,
  );
}

/// [cachedBoardProvider] with the device's queue on top: the matches played here, the ones in
/// review and, offline, what can start.
final localBoardProvider = Provider.autoDispose
    .family<AsyncValue<MatBoard>, String>((ref, matId) {
      final source = ref.watch(cachedBoardProvider(matId));
      final offline = ref.watch(offlineSyncProvider);
      final now = ref.read(offlineSyncProvider.notifier).now();
      return source.whenData((board) {
        final local = <String, MatchView>{
          for (final m in board.matches)
            if (board.offline || offline.pendingFor(m.id).isNotEmpty)
              if (offline.local(m.id, now) case final match?) m.id: match.view,
        };
        return localBoard(
          board,
          local: local,
          inReview: {
            ...offline.heldForReview,
            if (board.offline)
              for (final MapEntry(:key, :value) in offline.views.entries)
                if (value.review != null) key,
          },
        );
      });
    });
