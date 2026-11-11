import 'dart:async';
import 'dart:convert';

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
    this.hidden = const [],
    this.views = const {},
    this.heldForReview = const {},
    this.connected = true,
  });

  /// The signed-in account's queue in order, the rejected ones included.
  final List<OfflineOp> ops;

  /// Actions of other accounts (or of every one while signed out): kept, never shown or sent.
  final List<OfflineOp> hidden;

  /// The last view the server sent of each match on the mat.
  final Map<String, MatchView> views;

  /// Matches a 409 put in review, until a newer view says how they are.
  final Set<String> heldForReview;

  /// The last request got an answer.
  final bool connected;

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
    List<OfflineOp>? hidden,
    Map<String, MatchView>? views,
    Set<String>? heldForReview,
    bool? connected,
  }) => OfflineState(
    ops: ops ?? this.ops,
    hidden: hidden ?? this.hidden,
    views: views ?? this.views,
    heldForReview: heldForReview ?? this.heldForReview,
    connected: connected ?? this.connected,
  );
}

final offlineSyncProvider = NotifierProvider<OfflineSync, OfflineState>(
  OfflineSync.new,
);

/// The referee's queue (docs/modulos/offline.md, "App"), on Android and on the web: every action
/// goes in with its id, time and `knownEvents`, and goes out to the server in order, one at a
/// time.
class OfflineSync extends Notifier<OfflineState> {
  /// Done once the queue and views on the device are loaded.
  late Future<void> ready;
  var _loaded = false;
  // The actions in the stored queue as this instance last read or wrote it. Another tab of the
  // same browser shares that queue: what is stored and not here came from it.
  var _lastStored = <String>{};
  Timer? _retry;
  var _flushing = false;
  var _prefetching = false;
  // Bumped by every sign-out: answers to requests from before it are dropped.
  var _generation = 0;
  // Whose actions [OfflineState.ops] holds; also kept in `queue.json` for a session restored
  // without network, whose token says nothing yet.
  String? _account;
  // Sign-ins and sign-outs, one after the other.
  Future<void> _sessionJob = Future.value();
  // Server time minus device time, from the last `serverTime`. Not in the state: it changes
  // with every poll and nothing on screen depends on it.
  var _clockOffset = Duration.zero;

  OfflineStore get _store => ref.read(offlineStoreProvider);
  ScoreboardRepository get _repository =>
      ref.read(scoreboardRepositoryProvider);

  @override
  OfflineState build() {
    ready = _load();
    ref.listen(
      sessionProvider.select((s) => (s.status, s.accountId, s.expired)),
      (_, session) {
        switch (session) {
          case (SessionStatus.restoring, _, _):
            break;
          case (SessionStatus.signedIn, final account, _):
            _serial(() => _enter(account ?? _account));
          case (SessionStatus.signedOut, _, true):
            _serial(_keepQueue);
          case (SessionStatus.signedOut, _, false):
            _serial(clear);
        }
      },
      fireImmediately: true,
    );
    // Another server: nothing saved for the old one is any use.
    ref.listen(serverProvider, (_, _) => _serial(_forgetAll));
    ref.onDispose(() => _retry?.cancel());
    return const OfflineState();
  }

  /// The device's time corrected with the server's.
  DateTime now() => ref.read(deviceClockProvider)().toUtc().add(_clockOffset);

  Future<void> _load() async {
    final queue = await _store.read('queue');
    final saved = await _store.read('views');
    if (!ref.mounted) return;
    _loaded = true;
    if (queue case {'session': final String account}) _account = account;
    if (saved case {'clockOffsetMs': final int ms}) {
      _clockOffset = Duration(milliseconds: ms);
    }
    final stored = _storedOps(queue);
    _lastStored = {for (final op in stored) op.opId};
    state = OfflineState(
      // Until the session says whose they are.
      hidden: stored,
      heldForReview: {
        if (queue case {'heldForReview': final List ids})
          for (final id in ids) id as String,
      },
      views: {
        if (saved case {'views': final Map views})
          for (final MapEntry(:key, :value) in views.entries)
            key as String: MatchView.fromJson(value as Map<String, dynamic>),
      },
    );
  }

  void _serial(Future<void> Function() job) {
    _sessionJob = _sessionJob.catchError((_) {}).then((_) => job());
  }

  /// Shows and sends [account]'s actions; a queue saved without account becomes its own.
  Future<void> _enter(String? account) async {
    await ready;
    if (!ref.mounted) return;
    _account = account;
    final all = [
      for (final op in [...state.ops, ...state.hidden])
        account != null && op.account == null ? op.ownedBy(account) : op,
    ];
    state = state.copyWith(
      ops: [
        for (final op in all)
          if (op.account == account) op,
      ],
      hidden: [
        for (final op in all)
          if (op.account != account) op,
      ],
    );
    await _saveQueue();
    if (!ref.mounted) return;
    for (final id in {for (final op in state.ops) op.matchId}) {
      if (state.views[id] == null) unawaited(_reload(id));
    }
    if (state.pendingCount > 0) unawaited(flush());
  }

  /// A view from a poll. While this match has actions queued it may already hold some of them,
  /// and `knownEvents` would count them twice: the view is taken only if the ones its timeline
  /// holds (by `opId`) are the first of the queue, and those leave it. Without a view (after a
  /// rejected session) there is nothing better to show. A view like the known one is not
  /// written nor shown again.
  Future<void> storeView(MatchView view) async {
    await ready;
    if (!ref.mounted) return;
    _clockOffset = _offsetFrom(view);
    final known = state.views[view.id];
    final older =
        known?.serverTime != null &&
        view.serverTime != null &&
        view.serverTime!.isBefore(known!.serverTime!);
    final applied = _appliedIn(view);
    final pending = state.pendingFor(view.id);
    final firstApplied =
        applied.isNotEmpty &&
        pending.take(applied.length).every((op) => applied.contains(op.opId));
    if ((known != null && pending.isNotEmpty && !firstApplied) || older) {
      return;
    }
    final held = state.heldForReview.contains(view.id);
    if (known != null && !held && applied.isEmpty && _sameView(known, view)) {
      return;
    }
    state = state.copyWith(
      ops: [
        for (final op in state.ops)
          if (!applied.contains(op.opId)) op,
      ],
      views: {...state.views, view.id: view},
      heldForReview: state.heldForReview.difference({view.id}),
    );
    if (applied.isNotEmpty || held) await _saveQueue();
    await _saveViews();
  }

  // Equal but for when the server computed them: the device counts the clock from the
  // timeline, so the time left is not news either.
  static bool _sameView(MatchView a, MatchView b) {
    String key(MatchView view) => jsonEncode(
      view.toJson()
        ..remove('serverTime')
        ..remove('remainingMs'),
    );
    return key(a) == key(b);
  }

  /// The queued actions of [view]'s match that its timeline already holds.
  Set<String> _appliedIn(MatchView view) {
    final inTimeline = {
      for (final e in view.timeline)
        if (e.opId != null) e.opId,
    };
    return {
      for (final op in state.pendingFor(view.id))
        if (inTimeline.contains(op.opId)) op.opId,
    };
  }

  /// Puts a referee action in the queue and starts sending. False, and nothing queued, when
  /// the device has no view of the match. Once loaded it is in the state before the first
  /// await: taps in a row each count the one before.
  Future<bool> enqueue(
    String matchId,
    MatchAction action, {
    Side? side,
    String? reason,
  }) async {
    if (!_loaded) await ready;
    final view = ref.mounted ? state.views[matchId] : null;
    if (view == null) return false;
    final op = OfflineOp(
      opId: const Uuid().v4(),
      matchId: matchId,
      action: action,
      side: side,
      reason: reason,
      at: now(),
      account: _account,
      knownEvents:
          view.knownEvents +
          state.pendingFor(matchId).length -
          _appliedIn(view).length,
    );
    state = state.copyWith(ops: [...state.ops, op]);
    await _saveQueue();
    unawaited(flush());
    return true;
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
      final applied = {op.opId, ..._appliedIn(view)};
      state = state.copyWith(
        ops: [
          for (final o in state.ops)
            if (!applied.contains(o.opId)) o,
        ],
        views: {...state.views, view.id: view},
        heldForReview: state.heldForReview.difference({view.id}),
        connected: true,
      );
      _clockOffset = _offsetFrom(view);
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

  /// Sign-out: nothing of this session stays on the device. Other accounts' actions stay.
  Future<void> clear() => _signOut(state.hidden);

  /// The server rejected the session: its actions stay to go out when the same account is back,
  /// but the views and boards (with names) go.
  Future<void> _keepQueue() => _signOut([...state.ops, ...state.hidden]);

  Future<void> _forgetAll() => _signOut(const []);

  Future<void> _signOut(List<OfflineOp> kept) async {
    await ready;
    if (!ref.mounted) return;
    _generation++;
    _retry?.cancel();
    _account = null;
    _clockOffset = Duration.zero;
    state = OfflineState(hidden: kept);
    try {
      if (kept.isEmpty) {
        await _store.clear();
      } else {
        await _saveQueue();
        await _store.clear(keep: const {'queue'});
      }
    } on Exception {
      // Nothing was saved without its folder.
    }
  }

  Duration _offsetFrom(MatchView view) {
    final serverTime = view.serverTime;
    return serverTime == null
        ? _clockOffset
        : serverTime.difference(ref.read(deviceClockProvider)());
  }

  Future<void> _saveQueue() async {
    await _takeInOtherTabs();
    if (!ref.mounted) return;
    final all = [...state.ops, ...state.hidden];
    _lastStored = {for (final op in all) op.opId};
    await _save('queue', {
      'session': _account,
      'ops': [for (final op in all) op.toJson()],
      'heldForReview': [...state.heldForReview],
    });
  }

  /// Actions another tab stored since this one last looked: they join this queue (and go out
  /// from here too; the server takes each `opId` once), so writing it never drops them.
  Future<void> _takeInOtherTabs() async {
    final Object? stored;
    try {
      stored = await _store.read('queue');
    } on Exception {
      return;
    }
    if (!ref.mounted) return;
    final known = {
      for (final op in [...state.ops, ...state.hidden]) op.opId,
    };
    final arrived = [
      for (final op in _storedOps(stored))
        if (!known.contains(op.opId) && !_lastStored.contains(op.opId)) op,
    ];
    if (arrived.isEmpty) return;
    state = state.copyWith(
      ops: [
        ...state.ops,
        for (final op in arrived)
          if (_account != null && op.account == _account) op,
      ],
      hidden: [
        ...state.hidden,
        for (final op in arrived)
          if (_account == null || op.account != _account) op,
      ],
    );
    for (final id in {for (final op in arrived) op.matchId}) {
      if (state.views[id] == null && _account != null) unawaited(_reload(id));
    }
    if (state.pendingCount > 0 && !_flushing) unawaited(flush());
  }

  static List<OfflineOp> _storedOps(Object? queue) => [
    if (queue case {'ops': final List ops})
      for (final op in ops) OfflineOp.fromJson(op as Map<String, dynamic>),
  ];

  /// Every action not sent yet, of any account, for the rescue CSV.
  List<OfflineOp> get unsent => [
    for (final op in [...state.ops, ...state.hidden])
      if (!op.rejected) op,
  ];

  Future<void> _saveViews() => _save('views', {
    'clockOffsetMs': _clockOffset.inMilliseconds,
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
