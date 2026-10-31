import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_api.dart';
import '../data/refresh_token_store.dart';

enum SessionStatus { restoring, signedOut, signedIn }

class SessionState {
  const SessionState(
    this.status, {
    this.accessToken,
    this.emailVerified = true,
  });

  static const signedOut = SessionState(SessionStatus.signedOut);

  final SessionStatus status;

  /// Null while signed in without network: the next request renews it.
  final String? accessToken;

  /// Unknown while offline; assumed true so the banner only shows on the server's word.
  final bool emailVerified;
}

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(dioProvider)),
);

final refreshTokenStoreProvider = Provider<RefreshTokenStore>(
  (ref) => kIsWeb
      ? const CookieRefreshTokenStore()
      : const SecureRefreshTokenStore(),
);

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

class SessionController extends Notifier<SessionState> {
  Future<String?>? _refreshing;

  AuthApi get _api => ref.read(authApiProvider);
  RefreshTokenStore get _store => ref.read(refreshTokenStoreProvider);

  @override
  SessionState build() {
    _restore();
    return const SessionState(SessionStatus.restoring);
  }

  Future<void> _restore() async {
    await refresh();
    if (state.status == SessionStatus.restoring) {
      // The server did not answer. A stored refresh token keeps the session (Offline rule);
      // the web cannot tell whether its cookie is still there.
      state = _store.inCookie
          ? SessionState.signedOut
          : const SessionState(SessionStatus.signedIn);
    }
  }

  /// One refresh at a time: concurrent 401s share it (the server rejects a reused refresh token).
  /// Returns the new access token, or null if there is none.
  Future<String?> refresh() {
    return _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
  }

  Future<String?> _refresh() async {
    final stored = await _store.read();
    if (!_store.inCookie && stored == null) {
      state = SessionState.signedOut;
      return null;
    }
    try {
      final tokens = await _api.refresh(stored);
      await _signIn(tokens);
      return tokens.accessToken;
    } on DioException catch (e) {
      // Only the server's "no" ends the session; a network failure keeps it for later.
      if (const {400, 401}.contains(e.response?.statusCode)) {
        await _signOutLocally();
      }
      return null;
    }
  }

  Future<void> login(String email, String password) async =>
      _signIn(await _api.login(email.trim(), password));

  /// Cancels a pending account deletion with the token from the 403 of the login.
  Future<void> restoreAccount(String restoreToken) async =>
      _signIn(await _api.restore(restoreToken));

  Future<void> logout() async {
    final stored = await _store.read();
    await _signOutLocally();
    try {
      await _api.logout(stored);
    } on DioException {
      // Signed out here already; the server session simply expires.
    }
  }

  /// The reset closes every session on the server, this one included.
  Future<void> resetPassword(String token, String newPassword) async {
    await _api.resetPassword(token, newPassword);
    await _signOutLocally();
  }

  /// After the email link. The access token still says unverified, so it asks for a new one.
  Future<void> emailVerified() async {
    if (state.status != SessionStatus.signedIn) return;
    state = SessionState(
      SessionStatus.signedIn,
      accessToken: state.accessToken,
    );
    await refresh();
  }

  /// The session response has no email; `/me` does.
  Future<void> resendVerification() async {
    final me = await ref
        .read(apiProvider)
        .get<Map<String, dynamic>>('/api/v1/me');
    await _api.resendVerification(me.data!['email'] as String);
  }

  Future<void> _signIn(SessionTokens tokens) async {
    final refreshToken = tokens.refreshToken;
    if (refreshToken != null) await _store.write(refreshToken);
    state = SessionState(
      SessionStatus.signedIn,
      accessToken: tokens.accessToken,
      emailVerified: tokens.emailVerified,
    );
  }

  Future<void> _signOutLocally() async {
    await _store.clear();
    state = SessionState.signedOut;
  }
}

/// Dio for the API with the access token; on a 401 it refreshes once and repeats the request.
final apiProvider = Provider<Dio>((ref) {
  final base = ref.watch(dioProvider);
  // Shares the base connection pool; dioProvider closes it.
  final dio = Dio(base.options)..httpClientAdapter = base.httpClientAdapter;
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(sessionProvider).accessToken;
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
        // Sent before a refresh that has already finished: the new token is enough.
        final current = ref.read(sessionProvider).accessToken;
        final sent = error.requestOptions.headers['Authorization'];
        final token = current != null && sent != 'Bearer $current'
            ? current
            : await ref.read(sessionProvider.notifier).refresh();
        if (token == null) {
          return handler.next(error);
        }
        final options = error.requestOptions
          ..extra['retried'] = true
          ..headers['Authorization'] = 'Bearer $token';
        try {
          handler.resolve(await dio.fetch(options));
        } on DioException catch (e) {
          handler.next(e);
        }
      },
    ),
  );
  return dio;
});
