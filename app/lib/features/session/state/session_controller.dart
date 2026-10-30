import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/session_api.dart';

// Provisional session for the phase 1 prototype (docs/modulos/prototipo-f1.md): tokens in memory
// only; the auth module's login screens will replace the screen that drives it.

enum SessionStatus { restoring, signedOut, signedIn }

class SessionState {
  const SessionState(this.status, [this.tokens]);

  final SessionStatus status;
  final SessionTokens? tokens;
}

final sessionApiProvider = Provider<SessionApi>(
  (ref) => SessionApi(ref.watch(dioProvider)),
);

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

class SessionController extends Notifier<SessionState> {
  Future<SessionTokens?>? _refreshing;

  @override
  SessionState build() {
    _restore();
    return const SessionState(SessionStatus.restoring);
  }

  // After a page reload the refresh cookie is still there: try it before asking to log in.
  Future<void> _restore() async {
    try {
      final tokens = await ref.read(sessionApiProvider).refresh(null);
      state = SessionState(SessionStatus.signedIn, tokens);
    } on DioException {
      state = const SessionState(SessionStatus.signedOut);
    }
  }

  Future<void> login(String username, String password) async {
    final tokens = await ref
        .read(sessionApiProvider)
        .login(username.trim(), password);
    state = SessionState(SessionStatus.signedIn, tokens);
  }

  /// One refresh at a time: concurrent 401s share it (the server rejects a reused refresh token).
  Future<SessionTokens?> refresh() {
    return _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
  }

  Future<SessionTokens?> _refresh() async {
    try {
      final tokens = await ref
          .read(sessionApiProvider)
          .refresh(state.tokens?.refreshToken);
      state = SessionState(SessionStatus.signedIn, tokens);
      return tokens;
    } on DioException {
      state = const SessionState(SessionStatus.signedOut);
      return null;
    }
  }

  Future<void> logout() async {
    final refreshToken = state.tokens?.refreshToken;
    state = const SessionState(SessionStatus.signedOut);
    try {
      await ref.read(sessionApiProvider).logout(refreshToken);
    } on DioException {
      // Signed out here already; the server session simply expires.
    }
  }
}

/// Dio for the API with the access token; on a 401 it refreshes once and repeats the request.
final apiProvider = Provider<Dio>((ref) {
  final base = ref.watch(dioProvider);
  final dio = Dio(base.options);
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(sessionProvider).tokens?.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final retried = error.requestOptions.extra['retried'] == true;
        if (error.response?.statusCode != 401 || retried) {
          return handler.next(error);
        }
        final tokens = await ref.read(sessionProvider.notifier).refresh();
        if (tokens == null) {
          return handler.next(error);
        }
        final options = error.requestOptions
          ..extra['retried'] = true
          ..headers['Authorization'] = 'Bearer ${tokens.accessToken}';
        try {
          handler.resolve(await dio.fetch(options));
        } on DioException catch (e) {
          handler.next(e);
        }
      },
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});
