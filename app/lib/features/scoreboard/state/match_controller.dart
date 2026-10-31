import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/match_view.dart';
import '../data/scoreboard_repository.dart';
import 'bell.dart';

/// The server is the source of truth; this resyncs often so a reload or a second device never drifts.
const matchRefresh = Duration(seconds: 2);

final matchControllerProvider = AsyncNotifierProvider.autoDispose
    .family<MatchController, MatchView, String>(MatchController.new);

class MatchController extends AsyncNotifier<MatchView> {
  MatchController(this.matchId);

  final String matchId;

  // Time since the last answer from the server: the clock counts down from there.
  final _sinceSync = Stopwatch();
  // Answers to requests started before the last applied one are stale and dropped.
  var _requests = 0;
  var _applied = 0;
  var _endRung = false;

  @override
  Future<MatchView> build() async {
    final timer = Timer.periodic(matchRefresh, (_) => _refresh());
    ref.onDispose(timer.cancel);
    final view = await ref.read(scoreboardRepositoryProvider).load(matchId);
    _endRung = view.endReason != null;
    _sinceSync
      ..reset()
      ..start();
    return view;
  }

  /// Clock left right now, counting down locally between answers from the server.
  Duration remainingNow() {
    final view = state.value;
    if (view == null) return Duration.zero;
    if (!view.running) return view.remaining;
    final left = view.remaining - _sinceSync.elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  /// Called by the clock when it reaches zero here, before the server says so.
  void timeUp() {
    if (_endRung) return;
    _endRung = true;
    ref.read(bellProvider).ring();
  }

  /// Sends a referee action; returns the server's reason when it refuses it.
  Future<String?> send(MatchAction action, {Side? side, String? reason}) async {
    final request = ++_requests;
    try {
      final view = await ref
          .read(scoreboardRepositoryProvider)
          .send(matchId, action, side: side, reason: reason);
      _apply(view, request);
      return null;
    } on DioException catch (e) {
      unawaited(_refresh());
      final body = e.response?.data;
      return body is Map && body['detail'] is String
          ? body['detail'] as String
          : '';
    }
  }

  Future<void> _refresh() async {
    final request = ++_requests;
    try {
      _apply(
        await ref.read(scoreboardRepositoryProvider).load(matchId),
        request,
      );
    } on DioException {
      // Keep showing the last state; the next poll tries again.
    }
  }

  void _apply(MatchView view, int request) {
    if (request < _applied) return;
    _applied = request;
    final previous = state.value;
    if (previous != null) {
      final started = !previous.running && view.running;
      final ended = previous.endReason == null && view.endReason != null;
      if (started || (ended && !_endRung)) {
        ref.read(bellProvider).ring();
      }
    }
    if (view.endReason != null) {
      _endRung = true;
    } else if (previous?.endReason != null) {
      // An undo reopened the match: its next end rings again.
      _endRung = false;
    }
    _sinceSync
      ..reset()
      ..start();
    state = AsyncData(view);
  }
}
