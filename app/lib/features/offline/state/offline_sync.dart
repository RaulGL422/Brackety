import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../auth/data/api_error.dart';
import '../../auth/state/session_controller.dart';
import '../../mat/data/mat_board.dart';
import '../../scoreboard/data/match_view.dart';
import '../../scoreboard/data/scoreboard_repository.dart';
import '../../server/state/server_providers.dart';
import '../data/local_match.dart';
import '../data/offline_op.dart';
import '../data/offline_store.dart';

/// Only the Android app queues the referee's actions; the web sends them as always.
final offlineEnabledProvider = Provider<bool>(
  (ref) => ref.watch(serverSelectableProvider),
);

/// The device's clock, so tests can fix it.
final deviceClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// While actions wait and the server does not answer, it tries again this often.
const offlineRetry = Duration(seconds: 3);

const _reviewCodes = {'MATCH_CONFLICT', 'MATCH_IN_REVIEW'};

class OfflineState {
  const OfflineState({
    this.ops = const [],
    this.views = const {},
    this.heldForReview = const {},
    this.connected = true,
    this.clockOffset = Duration.zero,
  });

  /// The queue in order, the rejected ones included.
  final List<OfflineOp> ops;

  /// The last view the server sent of each match on the mat.
  final Map<String, MatchView> views;

  /// Matches a 409 put in review, until a newer view says how they are.
  final Set<String> heldForReview;

  /// The last request got an answer.
  final bool connected;

  /// Server time minus device time, from the last `serverTime`.
  final Duration clockOffset;

  List<OfflineOp> pendingFor(String matchId) => [
    for (final op in ops)
      if (op.matchId == matchId && !op.rejected) op,
  ];

  int get pendingCount => ops.where((op) => !op.rejected).length;

  List<OfflineOp> get rejected => [
    for (final op in ops)
      if (op.rejected) op,
  ];

  /// The match as the device shows it; null if it never got a view of it.
  LocalMatch? local(String matchId, DateTime now) {
    final view = views[matchId];
    return view == null
        ? null
        : LocalMatch.project(
            view,
            pendingFor(matchId),
            now,
            heldForReview: heldForReview.contains(matchId),
          );
  }

  OfflineState copyWith({
    List<OfflineOp>? ops,
    Map<String, MatchView>? views,
    Set<String>? heldForReview,
    bool? connected,
    Duration? clockOffset,
  }) => OfflineState(
    ops: ops ?? this.ops,
    views: views ?? this.views,
    heldForReview: heldForReview ?? this.heldForReview,
    connected: connected ?? this.connected,
    clockOffset: clockOffset ?? this.clockOffset,
  );
}

final offlineSyncProvider = NotifierProvider<OfflineSync, OfflineState>(
  OfflineSync.new,
);

/// The referee's queue (docs/modulos/offline.md, "App (APK)"): every action goes in with its
/// id, time and `knownEvents`, and goes out to the server in order, one at a time.
class OfflineSync extends Notifier<OfflineState> {
  /// Done once the queue and views on the device are loaded.
  late Future<void> ready;
  Timer? _retry;
  var _flushing = false;
  var _prefetching = false;
  // Bumped by [clear]: answers to requests from before it are dropped.
  var _generation = 0;

  OfflineStore get _store => ref.read(offlineStoreProvider);
  ScoreboardRepository get _repository =>
      ref.read(scoreboardRepositoryProvider);

  @override
  OfflineState build() {
    ref.listen(sessionProvider.select((s) => s.status), (_, status) {
      if (status == SessionStatus.signedOut) unawaited(clear());
    });
    ref.onDispose(() => _retry?.cancel());
    ready = _load();
    return const OfflineState();
  }

  /// The device's time corrected with the server's.
  DateTime now() =>
      ref.read(deviceClockProvider)().toUtc().add(state.clockOffset);

  Future<void> _load() async {
    final queue = await _store.read('queue');
    final saved = await _store.read('views');
    if (!ref.mounted) return;
    state = OfflineState(
      ops: [
        if (queue case {'ops': final List ops})
          for (final op in ops) OfflineOp.fromJson(op as Map<String, dynamic>),
      ],
      heldForReview: {
        if (queue case {'heldForReview': final List ids})
          for (final id in ids) id as String,
      },
      views: {
        if (saved case {'views': final Map views})
          for (final MapEntry(:key, :value) in views.entries)
            key as String: MatchView.fromJson(value as Map<String, dynamic>),
      },
      clockOffset: switch (saved) {
        {'clockOffsetMs': final int ms} => Duration(milliseconds: ms),
        _ => Duration.zero,
      },
    );
    if (state.pendingCount > 0) unawaited(flush());
  }

  /// A view from a poll. Ignored while this match has actions in the queue: it may already hold
  /// some of them, and `knownEvents` would count them twice.
  Future<void> storeView(MatchView view) async {
    await ready;
    if (!ref.mounted) return;
    final offset = _offsetFrom(view);
    final known = state.views[view.id];
    final older =
        known?.serverTime != null &&
        view.serverTime != null &&
        view.serverTime!.isBefore(known!.serverTime!);
    if (state.pendingFor(view.id).isNotEmpty || older) {
      state = state.copyWith(clockOffset: offset);
      return;
    }
    state = state.copyWith(
      views: {...state.views, view.id: view},
      heldForReview: state.heldForReview.difference({view.id}),
      clockOffset: offset,
    );
    await _saveViews();
  }

  /// Puts a referee action in the queue and starts sending. The match must have a view here.
  Future<void> enqueue(
    String matchId,
    MatchAction action, {
    Side? side,
    String? reason,
  }) async {
    await ready;
    if (!ref.mounted) return;
    final op = OfflineOp(
      opId: const Uuid().v4(),
      matchId: matchId,
      action: action,
      side: side,
      reason: reason,
      at: now(),
      knownEvents:
          state.views[matchId]!.knownEvents + state.pendingFor(matchId).length,
    );
    state = state.copyWith(ops: [...state.ops, op]);
    await _saveQueue();
    unawaited(flush());
  }

  /// Sends the queue in order until it is empty or the server stops answering.
  Future<void> flush() async {
    await ready;
    if (!ref.mounted) return;
    if (_flushing) return;
    _flushing = true;
    _retry?.cancel();
    try {
      while (ref.mounted) {
        final op = state.ops.where((o) => !o.rejected).firstOrNull;
        if (op == null) break;
        if (!await _send(op)) {
          if (ref.mounted) _retry = Timer(offlineRetry, flush);
          break;
        }
      }
    } finally {
      _flushing = false;
    }
  }

  /// False when it has to wait and try again.
  Future<bool> _send(OfflineOp op) async {
    final generation = _generation;
    try {
      final view = await _repository.sendOp(op);
      if (!ref.mounted || generation != _generation) return false;
      state = state.copyWith(
        ops: [
          for (final o in state.ops)
            if (o.opId != op.opId) o,
        ],
        views: {...state.views, view.id: view},
        heldForReview: state.heldForReview.difference({view.id}),
        connected: true,
        clockOffset: _offsetFrom(view),
      );
      await _saveQueue();
      await _saveViews();
      return true;
    } on DioException catch (e) {
      if (!ref.mounted || generation != _generation) return false;
      final error = ApiError.from(e);
      final status = error.status;
      state = state.copyWith(connected: status != null);
      // No answer, the session being renewed or the server failing: the same op, later.
      if (status == null || status == 401 || status >= 500) return false;
      if (status == 409 && _reviewCodes.contains(error.code)) {
        // The server keeps them for the club: they leave the queue.
        state = state.copyWith(
          ops: [
            for (final o in state.ops)
              if (o.matchId != op.matchId || o.rejected) o,
          ],
          heldForReview: {...state.heldForReview, op.matchId},
        );
        await _saveQueue();
        unawaited(_reload(op.matchId));
        return true;
      }
      // Refused for good: this one and the later ones of its match, which counted on it.
      state = state.copyWith(
        ops: [
          for (final o in state.ops)
            o.matchId == op.matchId ? o.asRejected() : o,
        ],
      );
      await _saveQueue();
      return true;
    }
  }

  Future<void> _reload(String matchId) async {
    try {
      final view = await _repository.load(matchId);
      if (!ref.mounted) return;
      reportResponse();
      await storeView(view);
    } on DioException catch (e) {
      if (ref.mounted && ApiError.from(e).noResponse) reportNoResponse();
    }
  }

  /// Another request got an answer: the network is back, so the queue goes now.
  void reportResponse() {
    if (!state.connected) state = state.copyWith(connected: true);
    if (state.pendingCount > 0 && !_flushing) unawaited(flush());
  }

  void reportNoResponse() {
    if (state.connected) state = state.copyWith(connected: false);
  }

  /// Keeps the views of [board]'s matches up to date, so any of them can open without network.
  Future<void> syncBoard(MatBoard board) async {
    await ready;
    if (!ref.mounted) return;
    if (_prefetching) return;
    _prefetching = true;
    try {
      final onMat = {for (final m in board.matches) m.id};
      final kept = {
        for (final MapEntry(:key, :value) in state.views.entries)
          if (onMat.contains(key) || state.pendingFor(key).isNotEmpty)
            key: value,
      };
      if (kept.length != state.views.length) {
        state = state.copyWith(views: kept);
        await _saveViews();
      }
      for (final m in board.matches) {
        if (!ref.mounted || !_stale(m)) continue;
        final view = await _repository.load(m.id);
        await storeView(view);
      }
    } on DioException catch (e) {
      if (ref.mounted && ApiError.from(e).noResponse) reportNoResponse();
    } finally {
      _prefetching = false;
    }
  }

  bool _stale(BoardMatch m) {
    if (state.pendingFor(m.id).isNotEmpty) return false;
    final view = state.views[m.id];
    if (view == null) return m.status != MatchStatus.finished;
    return view.status != m.status ||
        (view.review != null) != m.inReview ||
        view.red.points != m.redScore ||
        view.blue.points != m.blueScore;
  }

  /// The last board of a mat, for when the server does not answer.
  Future<void> saveBoard(String matId, Object? json) =>
      _save('board-$matId', json);

  Future<Object?> cachedBoard(String matId) => _store.read('board-$matId');

  /// Forgets the actions the server refused, once the referee has seen them.
  Future<void> dismissRejected() async {
    await ready;
    if (!ref.mounted) return;
    state = state.copyWith(
      ops: [
        for (final op in state.ops)
          if (!op.rejected) op,
      ],
    );
    await _saveQueue();
  }

  /// Sign-out: nothing of this session stays on the device.
  Future<void> clear() async {
    await ready;
    if (!ref.mounted) return;
    _generation++;
    _retry?.cancel();
    state = const OfflineState();
    try {
      await _store.clear();
    } on Exception {
      // Nothing was saved without its folder.
    }
  }

  Duration _offsetFrom(MatchView view) {
    final serverTime = view.serverTime;
    return serverTime == null
        ? state.clockOffset
        : serverTime.difference(ref.read(deviceClockProvider)());
  }

  Future<void> _saveQueue() => _save('queue', {
    'ops': [for (final op in state.ops) op.toJson()],
    'heldForReview': [...state.heldForReview],
  });

  Future<void> _saveViews() => _save('views', {
    'clockOffsetMs': state.clockOffset.inMilliseconds,
    'views': {
      for (final MapEntry(:key, :value) in state.views.entries)
        key: value.toJson(),
    },
  });

  Future<void> _save(String name, Object? json) async {
    try {
      await _store.write(name, json);
    } on Exception {
      // Without its folder the queue still works, only not across restarts.
    }
  }
}
