import 'dart:convert';

import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/browser_storage.dart';
import '../data/account_api.dart';
import '../data/auth_api.dart';
import '../data/refresh_token_store.dart';
import '../data/registration.dart';

enum SessionStatus { restoring, signedOut, signedIn }

/// Why the server ended the session, for the sign-in screen to explain.
sealed class SignedOutNotice {
  const SignedOutNotice();
}

class AccountDeletionScheduled extends SignedOutNotice {
  const AccountDeletionScheduled(this.deletesOn);

  final DateTime deletesOn;
}

class PasswordRemoved extends SignedOutNotice {
  const PasswordRemoved();
}

class SessionState {
  const SessionState(
    this.status, {
    this.accessToken,
    this.accountId,
    this.emailVerified = true,
    this.notice,
    this.expired = false,
  });

  static const signedOut = SessionState(SessionStatus.signedOut);

  /// Signed out because the server rejected the refresh (expired or revoked session).
  static const rejected = SessionState(SessionStatus.signedOut, expired: true);

  final SessionStatus status;

  /// Null while signed in without network: the next request renews it.
  final String? accessToken;

  /// The `sub` of [accessToken]; null without one.
  final String? accountId;

  /// Unknown while offline; assumed true so the banner only shows on the server's word.
  final bool emailVerified;

  /// Only while signed out by [SessionController.sessionsClosed].
  final SignedOutNotice? notice;

  /// Only while signed out by the server's "no" to a refresh, not by the user or the account.
  final bool expired;
}

/// The account id the server put in the token's `sub`; null if it is not a readable JWT.
String? accountIdOf(String accessToken) {
  final parts = accessToken.split('.');
  if (parts.length != 3) return null;
  try {
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    return payload is Map && payload['sub'] is String
        ? payload['sub'] as String
        : null;
  } on FormatException {
    return null;
  }
}

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(dioProvider)),
);

final accountApiProvider = Provider<AccountApi>(
  (ref) => AccountApi(ref.watch(apiProvider)),
);

final refreshTokenStoreProvider = Provider<RefreshTokenStore>(
  (ref) => kIsWeb
      ? CookieRefreshTokenStore(ref.watch(browserStorageProvider))
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
      // The server did not answer. A session from the last run stays (Offline rule): the next
      // request renews it, or the server's "no" ends it then.
      state = await _store.hasSession()
          ? const SessionState(SessionStatus.signedIn)
          : SessionState.signedOut;
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
        await _signOutLocally(expired: true);
      }
      return null;
    }
  }

  Future<void> login(String email, String password) async =>
      _signIn(await _api.login(email.trim(), password));

  /// Registers and signs straight in; returns whether it did. A failed registration throws.
  /// A failed sign-in (the email already had an account with another password, a lock, no
  /// network) returns false and the app shows the same neutral "check your email" as always,
  /// so nothing reveals whether the email was taken.
  Future<bool> register(Registration registration) async {
    await _api.register(registration);
    try {
      await login(registration.email, registration.password);
      return true;
    } on DioException {
      return false;
    }
  }

  /// Cancels a pending account deletion with the token from the 403 of the login.
  Future<void> restoreAccount(String restoreToken) async =>
      _signIn(await _api.restore(restoreToken));

  Future<void> logout() async {
    // A refresh finishing after this would sign the user back in with a token never revoked.
    await _refreshing;
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

  /// The server has just closed every session, this one included (account deleted, password
  /// removed, email changed): its refresh token is dead, so there is no logout to send.
  Future<void> sessionsClosed([SignedOutNotice? notice]) async {
    await _refreshing;
    await _store.clear();
    state = SessionState(SessionStatus.signedOut, notice: notice);
  }

  /// After the email link. The access token still says unverified, so it asks for a new one.
  Future<void> emailVerified() async {
    if (state.status != SessionStatus.signedIn) return;
    state = SessionState(
      SessionStatus.signedIn,
      accessToken: state.accessToken,
      accountId: state.accountId,
    );
    await refresh();
  }

  /// The session response has no email; `/me` does.
  Future<void> resendVerification() async {
    final me = await ref.read(accountApiProvider).me();
    await _api.resendVerification(me.email);
  }

  Future<void> _signIn(SessionTokens tokens) async {
    final refreshToken = tokens.refreshToken;
    if (refreshToken != null) await _store.write(refreshToken);
    state = SessionState(
      SessionStatus.signedIn,
      accessToken: tokens.accessToken,
      accountId: accountIdOf(tokens.accessToken),
      emailVerified: tokens.emailVerified,
    );
  }

  Future<void> _signOutLocally({bool expired = false}) async {
    await _store.clear();
    state = expired ? SessionState.rejected : SessionState.signedOut;
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
