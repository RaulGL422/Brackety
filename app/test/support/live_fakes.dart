import 'dart:async';
import 'dart:convert';

import 'package:brackety/core/live/live_connection.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// The server's live socket (`LiveHub`) without a server: it signs in any token, follows every
/// topic asked, and the test pushes changes, drops the sockets or takes the server down.
class FakeLiveServer {
  /// New sockets fail at once, as with the server off.
  bool down = false;

  /// Tokens it refuses, closing with 4001 as the server does.
  final refusedTokens = <String>{};

  final sockets = <FakeSocket>[];

  /// Every `auth` token received, in order.
  final tokens = <String>[];

  FakeSocket connect(Uri uri) {
    final socket = FakeSocket._(this, uri);
    sockets.add(socket);
    if (down) scheduleMicrotask(() => socket.closeFromServer());
    return socket;
  }

  Iterable<FakeSocket> get open => sockets.where((s) => !s.closed);

  /// What the server pushes after a write: `changed` to every socket following one of [topics].
  void push(Set<String> topics) {
    for (final socket in open.toList()) {
      final theirs = socket.watching.where(topics.contains).toList();
      if (theirs.isNotEmpty) {
        socket.receive({'type': 'changed', 'topics': theirs});
      }
    }
  }

  /// The connection is lost (wifi gone, server restarted).
  void dropAll([int? code]) {
    for (final socket in open.toList()) {
      socket.closeFromServer(code);
    }
  }

  void _handle(FakeSocket socket, Map<String, dynamic> message) {
    switch (message) {
      case {'type': 'auth', 'token': final String token}:
        tokens.add(token);
        if (refusedTokens.contains(token)) {
          socket.closeFromServer(4001);
        } else {
          socket.receive({'type': 'ready'});
        }
      case {'type': 'watch', 'topics': final List topics}:
        socket.watching = {for (final t in topics) t as String};
        socket.receive({
          'type': 'watching',
          'topics': [...socket.watching],
        });
    }
  }
}

class FakeSocket with StreamChannelMixin<dynamic> implements WebSocketChannel {
  FakeSocket._(this._server, this.uri);

  final FakeLiveServer _server;
  final Uri uri;
  final _incoming = StreamController<dynamic>();
  var watching = <String>{};
  var closed = false;
  int? _closeCode;

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  late final WebSocketSink sink = _FakeSink(this);

  @override
  Future<void> get ready => Future.value();

  @override
  String? get protocol => null;

  @override
  int? get closeCode => _closeCode;

  @override
  String? get closeReason => null;

  void receive(Object message) {
    if (!closed) _incoming.add(jsonEncode(message));
  }

  void closeFromServer([int? code]) {
    if (closed) return;
    closed = true;
    _closeCode = code;
    unawaited(_incoming.close());
  }

  void _fromClient(dynamic data) {
    if (closed) return;
    _server._handle(this, jsonDecode(data as String) as Map<String, dynamic>);
  }
}

class _FakeSink implements WebSocketSink {
  _FakeSink(this._socket);

  final FakeSocket _socket;

  @override
  void add(dynamic data) => _socket._fromClient(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) => stream.forEach(add);

  @override
  Future<void> close([int? closeCode, String? closeReason]) async =>
      _socket.closeFromServer(closeCode);

  @override
  Future<void> get done => Future.value();
}

/// A socket that never answers: screens keep their slow fallback and nothing touches the
/// network. For tests that are not about live updates.
LiveSocketConnect get silentLive => _silent;

WebSocketChannel _silent(Uri uri) => _SilentSocket();

class _SilentSocket
    with StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  final _incoming = StreamController<dynamic>();

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  late final WebSocketSink sink = _SilentSink(_incoming);

  @override
  Future<void> get ready => Future.value();

  @override
  String? get protocol => null;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;
}

class _SilentSink implements WebSocketSink {
  _SilentSink(this._incoming);

  final StreamController<dynamic> _incoming;

  @override
  void add(dynamic data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) => stream.drain<void>();

  @override
  Future<void> close([int? closeCode, String? closeReason]) =>
      _incoming.close();

  @override
  Future<void> get done => Future.value();
}
