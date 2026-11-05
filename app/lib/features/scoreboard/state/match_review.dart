import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/match_view.dart';
import '../data/scoreboard_repository.dart';

const _watchRefresh = Duration(seconds: 5);

/// A match as the club follows it: refreshed on its own, read only.
final watchedMatchProvider = FutureProvider.autoDispose
    .family<MatchView, String>((ref, matchId) {
      final timer = Timer(_watchRefresh, ref.invalidateSelf);
      ref.onDispose(timer.cancel);
      return ref.watch(scoreboardRepositoryProvider).load(matchId);
    });

final matchReviewProvider = NotifierProvider.autoDispose
    .family<MatchReviewController, bool, String>(MatchReviewController.new);

/// The club's decision on a match in review; the state says whether it is being sent.
class MatchReviewController extends Notifier<bool> {
  MatchReviewController(this.matchId);

  final String matchId;

  @override
  bool build() => false;

  /// Null when the server did not take it (the match view tells why on the next refresh).
  Future<ReviewOutcome?> resolve(ReviewDecision decision) async {
    if (state) return null;
    state = true;
    try {
      return await ref
          .read(scoreboardRepositoryProvider)
          .review(matchId, decision);
    } on DioException {
      return null;
    } finally {
      if (ref.mounted) {
        state = false;
        ref.invalidate(watchedMatchProvider(matchId));
      }
    }
  }
}
