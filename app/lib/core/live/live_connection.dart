import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:brackety_core/brackety_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../features/auth/state/session_controller.dart';

/// Opens the live socket; tests replace it.
typedef LiveSocketConnect = WebSocketChannel Function(Uri uri);

final liveSocketConnectProvider = Provider<LiveSocketConnect>(
  (ref) => WebSocketChannel.connect,
);

/// One socket for the whole app, open while some screen follows a topic and the user is signed
/// in (docs/modulos/tiempo-real.md).
final liveConnectionProvider = Provider<LiveConnection>((ref) {
  final live = LiveConnection(ref);
  ref.listen(sessionProvider.select((s) => s.status), (_, status) {
    status == SessionStatus.signedIn ? live._connect() : live._drop();
  });
  ref.onDispose(live._dispose);
  return live;
});

/// The live socket of the API at [apiBase]: same host and path, `ws` or `wss`.
Uri liveUri(String apiBase) {
  final base = Uri.parse(apiBase);
  final path = base.path.endsWith('/')
      ? base.path.substring(0, base.path.length - 1)
      : base.path;
  return base.replace(
    scheme: base.scheme == 'https' ? 'wss' : 'ws',
    path: '$path/api/v1/live',
  );
}

/// A screen's interest in [topics]; [cancel] when it goes.
class LiveFollow {
  LiveFollow._(this._live, this.topics, this._onChange);

  final LiveConnection _live;
  final Set<String> topics;
  final void Function() _onChange;

  /// The server confirmed it pushes these topics: polling can slow down.
  bool get connected => _live.connected;

  void cancel() => _live._remove(this);
}

/// A plain WebSocket that only says "this changed" (the server's `LiveHub`): each screen fetches
/// again by REST. It signs in with the access token in its first message, reconnects on its own
/// (1 s, 2 s, 4 s… up to 15 s) and, on every (re)connection, has each screen fetch once, since
/// what changed meanwhile is unknown.
class LiveConnection {
  LiveConnection(this._ref);

  /// No message for this long (the server pings every 25 s): the socket is dead.
  static const silence = Duration(seconds: 60);
  static const maxRetry = Duration(seconds: 15);

  /// Screens come and go (each refetch builds them again): the socket waits before closing.
  static const idleClose = Duration(seconds: 10);

  final Ref _ref;
  final _follows = <LiveFollow>{};
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _messages;
  Timer? _retry;
  Timer? _watchdog;
  Timer? _idle;
  var _connecting = false;
  var _attempt = 0;
  var _authenticated = false;
  var _renewToken = false;
  var _disposed = false;
  var _sent = <String>{};
  var _confirmed = <String>{};

  /// Signed in on the server and following what it was asked for.
  bool get connected => _authenticated && _confirmed.isNotEmpty;

  /// Calls [onChange] when any of [topics] changes on the server, and when the socket
  /// (re)connects.
  LiveFollow follow(Set<String> topics, void Function() onChange) {
    final follow = LiveFollow._(this, topics, onChange);
    _follows.add(follow);
    _idle?.cancel();
    if (_channel == null) {
      unawaited(_connect());
    } else {
      _sendWatch();
    }
    return follow;
  }

  void _remove(LiveFollow follow) {
    _follows.remove(follow);
    if (_follows.isNotEmpty || _disposed) {
      _sendWatch();
      return;
    }
    _idle?.cancel();
    _idle = Timer(idleClose, () {
      if (_follows.isEmpty) _drop();
    });
  }

  Future<void> _connect() async {
    _retry?.cancel();
    if (_disposed || _connecting || _channel != null || _follows.isEmpty) {
      return;
    }
    _connecting = true;
    try {
      final session = _ref.read(sessionProvider.notifier);
      final token = _renewToken
          ? await session.refresh()
          : _ref.read(sessionProvider).accessToken ?? await session.refresh();
      if (_disposed || _follows.isEmpty) return;
      if (token == null) {
        _scheduleRetry();
        return;
      }
      _renewToken = false;
      final channel = _ref.read(liveSocketConnectProvider)(
        liveUri(_ref.read(apiBaseUrlProvider)),
      );
      _channel = channel;
      // A failed handshake also ends the stream below.
      unawaited(channel.ready.then((_) {}, onError: (_) {}));
      _messages = channel.stream.listen(
        _onMessage,
        onDone: () => _closed(channel),
        onError: (_) => _closed(channel),
        cancelOnError: true,
      );
      channel.sink.add(jsonEncode({'type': 'auth', 'token': token}));
      _watchSilence();
    } finally {
      _connecting = false;
    }
  }

  void _onMessage(dynamic data) {
    _watchSilence();
    final Object? message;
    try {
      message = jsonDecode(data as String);
    } on Object {
      return;
    }
    switch (message) {
      case {'type': 'ready'}:
        _attempt = 0;
        _authenticated = true;
        _sendWatch(now: true);
      case {'type': 'watching', 'topics': final List topics}:
        final before = _confirmed;
        _confirmed = {for (final t in topics) t as String};
        for (final follow in _follows.toList()) {
          if (follow.topics.any((t) => !before.contains(t))) follow._onChange();
        }
      case {'type': 'changed', 'topics': final List topics}:
        final changed = {for (final t in topics) t as String};
        for (final follow in _follows.toList()) {
          if (follow.topics.any(changed.contains)) follow._onChange();
        }
    }
  }

  Timer? _watchDebounce;

  // Screens rebuilt in a row leave the same topics: one message for all of them, and none when
  // nothing changed.
  void _sendWatch({bool now = false}) {
    _watchDebounce?.cancel();
    if (!_authenticated) return;
    if (!now) {
      _watchDebounce = Timer(
        const Duration(milliseconds: 100),
        () => _sendWatch(now: true),
      );
      return;
    }
    final wanted = {for (final f in _follows) ...f.topics};
    if (_sent.length == wanted.length && _sent.containsAll(wanted)) return;
    _sent = wanted;
    _channel?.sink.add(
      jsonEncode({
        'type': 'watch',
        'topics': [...wanted],
      }),
    );
  }

  void _watchSilence() {
    _watchdog?.cancel();
    _watchdog = Timer(silence, () => _channel?.sink.close());
  }

  void _closed(WebSocketChannel channel) {
    if (_channel != channel) return;
    // 4001: the token was refused or has expired; the next attempt gets a new one.
    if (channel.closeCode == 4001) _renewToken = true;
    _reset();
    _scheduleRetry();
  }

  void _scheduleRetry() {
    _retry?.cancel();
    if (_disposed || _follows.isEmpty) return;
    final wait = Duration(
      seconds: min(maxRetry.inSeconds, 1 << min(_attempt, 4)),
    );
    _attempt++;
    _retry = Timer(wait, () => unawaited(_connect()));
  }

  /// Signed out or nobody follows anything: no socket and no retries.
  void _drop() {
    _retry?.cancel();
    final channel = _channel;
    _reset();
    unawaited(channel?.sink.close());
  }

  void _reset() {
    _watchdog?.cancel();
    _watchDebounce?.cancel();
    unawaited(_messages?.cancel());
    _messages = null;
    _channel = null;
    _authenticated = false;
    _sent = {};
    _confirmed = {};
  }

  void _dispose() {
    _disposed = true;
    _idle?.cancel();
    _drop();
  }
}
