import 'dart:async';

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
import 'match_review.dart';

final matchControllerProvider = AsyncNotifierProvider.autoDispose
    .family<MatchController, MatchView, String>(MatchController.new);

/// Why an action did not go in: the device's own rules ([local]) or the server's words.
class ActionRefusal {
  const ActionRefusal.local(MatchRefusal this.local) : detail = null;
  const ActionRefusal.server(String this.detail) : local = null;

  final MatchRefusal? local;
  final String? detail;
}

/// The referee's match, on Android and on the web: every action goes through the device's queue
/// and the match shows the server's last view with the queued actions on top, so a tap shows at
/// once however fast they come (docs/modulos/offline.md). The server's view comes again on
/// every change it signals (live socket) and, as a safety net, now and then ([Poller]).
class MatchController extends AsyncNotifier<MatchView> {
  MatchController(this.matchId);

  final String matchId;

  // Time since the shown view was computed: the clock counts down from there.
  final _sinceSync = Stopwatch();
  var _endRung = false;
  late Poller _poller;

  OfflineSync get _sync => ref.read(offlineSyncProvider.notifier);
  ScoreboardRepository get _repository =>
      ref.read(scoreboardRepositoryProvider);

  @override
  Future<MatchView> build() async {
    _poller = startLivePolling(ref, matchTopics(matchId), _refresh);
    final view = await _poller.track(_load);
    _endRung = view.endReason != null;
    _sinceSync
      ..reset()
      ..start();
    return view;
  }

  Future<MatchView> _load() async {
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

  /// Called by the clock when it reaches zero here, before the server says so. Nothing changes
  /// on the server at that moment, so nothing is pushed: it asks for the match now.
  void timeUp() {
    if (_endRung) return;
    _endRung = true;
    ref.read(bellProvider).play(BellSound.end);
    _poller.pollNow();
  }

  /// Puts a referee action in the queue; null when it went in. Checked and queued before the
  /// first await, so taps in a row each see the one before.
  Future<ActionRefusal?> send(
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
    try {
      final view = await _repository.load(matchId);
      _sync.reportResponse();
      await _sync.storeView(view);
    } on DioException catch (e) {
      if (ApiError.from(e).noResponse) _sync.reportNoResponse();
    }
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
