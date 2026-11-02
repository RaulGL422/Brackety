import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/session_controller.dart';
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
