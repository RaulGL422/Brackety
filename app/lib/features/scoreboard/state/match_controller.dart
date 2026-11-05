import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/api_error.dart';
import '../../mat/data/mat_board.dart';
import '../../offline/data/local_match.dart';
import '../../offline/state/offline_sync.dart';
import '../data/match_view.dart';
import '../data/scoreboard_repository.dart';
import '../data/tambo_match.dart';
import 'bell.dart';

/// The server is the source of truth; this resyncs often so a reload or a second device never drifts.
const matchRefresh = Duration(seconds: 2);

final matchControllerProvider = AsyncNotifierProvider.autoDispose
    .family<MatchController, MatchView, String>(MatchController.new);

/// Why an action did not go in: the device's own rules ([local]) or the server's words.
class ActionRefusal {
  const ActionRefusal.local(MatchRefusal this.local) : detail = null;
  const ActionRefusal.server(String this.detail) : local = null;

  final MatchRefusal? local;
  final String? detail;
}

/// On the web every action goes straight to the server. On Android ([offlineEnabledProvider])
/// it goes through the device's queue and the match shows the server's last view with the
/// queued actions on top (docs/modulos/offline.md).
class MatchController extends AsyncNotifier<MatchView> {
  MatchController(this.matchId);

  final String matchId;

  // Time since the shown view was computed: the clock counts down from there.
  final _sinceSync = Stopwatch();
  // Answers to requests started before the last applied one are stale and dropped.
  var _requests = 0;
  var _applied = 0;
  var _endRung = false;
  var _queued = false;

  OfflineSync get _sync => ref.read(offlineSyncProvider.notifier);
  ScoreboardRepository get _repository =>
      ref.read(scoreboardRepositoryProvider);

  @override
  Future<MatchView> build() async {
    final timer = Timer.periodic(matchRefresh, (_) => _refresh());
    ref.onDispose(timer.cancel);
    _queued = ref.read(offlineEnabledProvider);
    final view = _queued
        ? await _loadQueued()
        : await _repository.load(matchId);
    _endRung = view.endReason != null;
    _sinceSync
      ..reset()
      ..start();
    return view;
  }

  Future<MatchView> _loadQueued() async {
    ref.listen(offlineSyncProvider, (_, _) {
      final local = _local();
      if (state.hasValue && local != null) _show(local.view);
    });
    await _sync.ready;
    try {
      final view = await _repository.load(matchId);
      _sync.reportResponse();
      await _sync.storeView(view);
    } on DioException catch (e) {
      if (!ApiError.from(e).noResponse) rethrow;
      _sync.reportNoResponse();
      if (_local() == null) rethrow;
    }
    return _local()!.view;
  }

  LocalMatch? _local() =>
      ref.read(offlineSyncProvider).local(matchId, _sync.now());

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

  /// Sends a referee action; null when it went in (or into the queue).
  Future<ActionRefusal?> send(
    MatchAction action, {
    Side? side,
    String? reason,
  }) async {
    if (_queued) return _enqueue(action, side: side, reason: reason);
    final request = ++_requests;
    try {
      final view = await _repository.send(
        matchId,
        action,
        side: side,
        reason: reason,
      );
      _apply(view, request);
      return null;
    } on DioException catch (e) {
      unawaited(_refresh());
      final body = e.response?.data;
      return ActionRefusal.server(
        body is Map && body['detail'] is String ? body['detail'] as String : '',
      );
    }
  }

  Future<ActionRefusal?> _enqueue(
    MatchAction action, {
    Side? side,
    String? reason,
  }) async {
    final local = _local();
    if (local == null) return null;
    final now = _sync.now();
    final refusal =
        local.refuse(action, side, now) ??
        (action == MatchAction.start &&
                local.view.status == MatchStatus.pending &&
                _matBusy(local.view, now)
            ? MatchRefusal.matBusy
            : null);
    if (refusal != null) return ActionRefusal.local(refusal);
    await _sync.enqueue(matchId, action, side: side, reason: reason);
    return null;
  }

  // Another match of this mat in progress, as far as this device knows: the server would put
  // this one in review.
  bool _matBusy(MatchView view, DateTime now) {
    final offline = ref.read(offlineSyncProvider);
    return offline.views.keys.where((id) => id != matchId).any((id) {
      final other = offline.local(id, now)?.view;
      return other != null &&
          other.matId == view.matId &&
          other.status == MatchStatus.inProgress;
    });
  }

  Future<void> _refresh() async {
    if (_queued) {
      try {
        final view = await _repository.load(matchId);
        _sync.reportResponse();
        await _sync.storeView(view);
      } on DioException catch (e) {
        if (ApiError.from(e).noResponse) _sync.reportNoResponse();
      }
      return;
    }
    final request = ++_requests;
    try {
      _apply(await _repository.load(matchId), request);
    } on DioException {
      // Keep showing the last state; the next poll tries again.
    }
  }

  void _apply(MatchView view, int request) {
    if (request < _applied) return;
    _applied = request;
    _show(view);
  }

  void _show(MatchView view) {
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
