import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/polling.dart';
import '../../auth/data/api_error.dart';
import '../../mat/data/mat_board.dart';
import '../../offline/data/local_match.dart';
import '../../offline/state/offline_sync.dart';
import '../data/match_view.dart';
import '../data/scoreboard_repository.dart';
import '../data/tambo_match.dart';
import 'bell.dart';

/// The server is the source of truth; this resyncs often so a reload or a second device never
/// drifts. Counted from the end of the last poll ([Poller]).
const matchRefresh = Duration(seconds: 2);

final matchControllerProvider = AsyncNotifierProvider.autoDispose
    .family<MatchController, MatchView, String>(MatchController.new);

/// Why an action did not go in: the device's own rules ([local]), another tab or device wrote
/// first ([stale]), or the server's words.
class ActionRefusal {
  const ActionRefusal.local(MatchRefusal this.local)
    : detail = null,
      stale = false;
  const ActionRefusal.server(String this.detail) : local = null, stale = false;
  const ActionRefusal.stale() : local = null, detail = null, stale = true;

  final MatchRefusal? local;
  final String? detail;
  final bool stale;
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
  // Web: the most actions any answer showed. They only grow (an undo is one more), so this is
  // the latest the screen knows, even when an older answer is dropped.
  var _known = 0;
  // Web: actions go one at a time, each with what the one before it left.
  Future<void> _sending = Future.value();

  OfflineSync get _sync => ref.read(offlineSyncProvider.notifier);
  ScoreboardRepository get _repository =>
      ref.read(scoreboardRepositoryProvider);

  @override
  Future<MatchView> build() async {
    final poller = startPolling(ref, matchRefresh, _refresh);
    _queued = ref.read(offlineEnabledProvider);
    final view = await poller.track(
      () => _queued ? _loadQueued() : _repository.load(matchId),
    );
    _endRung = view.endReason != null;
    _known = view.knownEvents;
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
    ref.read(bellProvider).play(BellSound.end);
  }

  /// Sends a referee action; null when it went in (or into the queue).
  Future<ActionRefusal?> send(
    MatchAction action, {
    Side? side,
    String? reason,
    Duration? delta,
  }) async {
    if (_queued) {
      return _enqueue(action, side: side, reason: reason, delta: delta);
    }
    final previous = _sending;
    final turn = Completer<void>();
    _sending = turn.future;
    try {
      await previous;
      return await _sendNow(action, side: side, reason: reason, delta: delta);
    } finally {
      turn.complete();
    }
  }

  Future<ActionRefusal?> _sendNow(
    MatchAction action, {
    Side? side,
    String? reason,
    Duration? delta,
  }) async {
    final request = ++_requests;
    try {
      final view = await _repository.send(
        matchId,
        action,
        side: side,
        reason: reason,
        delta: delta,
        knownEvents: _known,
      );
      _apply(view, request);
      return null;
    } on DioException catch (e) {
      unawaited(_refresh());
      final body = e.response?.data;
      if (body is Map && body['code'] == 'MATCH_STALE') {
        return const ActionRefusal.stale();
      }
      return ActionRefusal.server(
        body is Map && body['detail'] is String ? body['detail'] as String : '',
      );
    }
  }

  Future<ActionRefusal?> _enqueue(
    MatchAction action, {
    Side? side,
    String? reason,
    Duration? delta,
  }) async {
    final local = _local();
    if (local == null) return const ActionRefusal.server('');
    final now = _sync.now();
    final refusal =
        local.refuse(action, side, now, delta: delta ?? Duration.zero) ??
        (action == MatchAction.start &&
                local.view.status == MatchStatus.pending &&
                _matBusy(local.view, now)
            ? MatchRefusal.matBusy
            : null);
    if (refusal != null) return ActionRefusal.local(refusal);
    final queued = await _sync.enqueue(
      matchId,
      action,
      side: side,
      reason: reason,
      delta: delta,
    );
    return queued ? null : const ActionRefusal.server('');
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
    _known = max(_known, view.knownEvents);
    if (request < _applied) return;
    _applied = request;
    _show(view);
  }

  void _show(MatchView view) {
    final previous = state.value;
    if (previous != null) {
      final started = !previous.running && view.running;
      final ended = previous.endReason == null && view.endReason != null;
      if (started) ref.read(bellProvider).play(BellSound.start);
      if (ended && !_endRung) ref.read(bellProvider).play(BellSound.end);
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
