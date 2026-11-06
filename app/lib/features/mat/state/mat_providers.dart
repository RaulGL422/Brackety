import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/api_error.dart';
import '../../auth/state/session_controller.dart';
import '../../offline/data/local_board.dart';
import '../../offline/state/offline_sync.dart';
import '../../scoreboard/data/match_view.dart';
import '../data/mat_board.dart';

/// The board refreshes on its own: other mats finish matches that change what is available here.
const boardRefresh = Duration(seconds: 5);

final matBoardProvider = FutureProvider.autoDispose.family<MatBoard, String>((
  ref,
  matId,
) async {
  final timer = Timer(boardRefresh, ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  final response = await ref
      .watch(apiProvider)
      .get<Map<String, dynamic>>('/api/v1/mats/$matId/board');
  return MatBoard.fromJson(response.data!);
});

/// The referee's board on Android: from the server, kept on the device, and from there when
/// the server does not answer ([MatBoard.offline]).
final cachedBoardProvider = FutureProvider.autoDispose.family<MatBoard, String>(
  (ref, matId) async {
    final timer = Timer(boardRefresh, ref.invalidateSelf);
    ref.onDispose(timer.cancel);
    final sync = ref.read(offlineSyncProvider.notifier);
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
      final board = MatBoard.fromJson(cached);
      return MatBoard(
        matNumber: board.matNumber,
        groups: board.groups,
        matches: board.matches,
        offline: true,
      );
    }
  },
);

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
