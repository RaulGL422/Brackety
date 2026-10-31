import 'dart:async';

import 'package:brackety/features/auth/data/auth_api.dart';
import 'package:brackety/features/auth/data/refresh_token_store.dart';
import 'package:brackety/features/auth/data/registration.dart';
import 'package:brackety/features/auth/state/session_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/misc.dart';

/// A server answer with [status] and an optional problem+json [body].
DioException httpError(
  int status, {
  Map<String, dynamic>? body,
  Map<String, List<String>> headers = const {},
}) => DioException(
  requestOptions: RequestOptions(),
  response: Response(
    requestOptions: RequestOptions(),
    statusCode: status,
    data: body,
    headers: Headers.fromMap(headers),
  ),
);

/// No answer at all: no network or a timeout.
DioException networkError() => DioException.connectionError(
  requestOptions: RequestOptions(),
  reason: 'offline',
);

/// The provider overrides every app test needs: [api] instead of the server and a web-like
/// cookie store, so the session restores itself when [FakeAuthApi.signedIn] is true.
List<Override> sessionOverrides(
  FakeAuthApi api, {
  RefreshTokenStore store = const CookieRefreshTokenStore(),
}) => [
  authApiProvider.overrideWithValue(api),
  refreshTokenStoreProvider.overrideWithValue(store),
];

/// Server auth without a server. Sign-in works when the password equals the email (like the
/// demo accounts); each `...Error` makes that call fail instead.
class FakeAuthApi implements AuthApi {
  FakeAuthApi({this.signedIn = false, this.issueRefreshTokens = false});

  bool signedIn;

  /// Android answers carry the refresh token; web answers do not.
  final bool issueRefreshTokens;
  bool emailVerified = true;

  DioException? loginError;
  DioException? restoreError;
  DioException? refreshError;
  DioException? registerError;
  DioException? verifyError;
  DioException? forgotError;
  DioException? resetError;

  /// While set and not completed, refreshes wait for it.
  Completer<void>? refreshGate;

  final logins = <String>[];
  final restores = <String>[];
  final refreshes = <String?>[];
  final logouts = <String?>[];
  final registrations = <Registration>[];
  final verifications = <String>[];
  final resends = <String>[];
  final forgotten = <String>[];
  final resets = <String>[];
  int _sessions = 0;

  SessionTokens _session() {
    _sessions++;
    signedIn = true;
    return SessionTokens(
      accessToken: 'access-$_sessions',
      refreshToken: issueRefreshTokens ? 'refresh-$_sessions' : null,
      emailVerified: emailVerified,
    );
  }

  static void _failWith(DioException? error) {
    if (error != null) throw error;
  }

  @override
  Future<SessionTokens> login(String email, String password) async {
    _failWith(loginError);
    if (email != password) throw httpError(401);
    logins.add(email);
    return _session();
  }

  @override
  Future<SessionTokens> restore(String restoreToken) async {
    _failWith(restoreError);
    restores.add(restoreToken);
    return _session();
  }

  @override
  Future<SessionTokens> refresh(String? refreshToken) async {
    refreshes.add(refreshToken);
    await refreshGate?.future;
    _failWith(refreshError);
    if (!signedIn) throw httpError(401);
    return _session();
  }

  @override
  Future<void> logout(String? refreshToken) async {
    logouts.add(refreshToken);
    signedIn = false;
  }

  @override
  Future<void> register(Registration registration) async {
    _failWith(registerError);
    registrations.add(registration);
  }

  @override
  Future<void> verifyEmail(String token) async {
    _failWith(verifyError);
    verifications.add(token);
    emailVerified = true;
  }

  @override
  Future<void> resendVerification(String email) async => resends.add(email);

  @override
  Future<void> forgotPassword(String email) async {
    _failWith(forgotError);
    forgotten.add(email);
  }

  @override
  Future<void> resetPassword(String token, String newPassword) async {
    _failWith(resetError);
    resets.add(token);
    signedIn = false;
  }
}

/// Secure storage in memory (Android) or the web's cookie when [inCookie].
class FakeRefreshTokenStore implements RefreshTokenStore {
  FakeRefreshTokenStore({this.token, this.inCookie = false});

  String? token;

  @override
  final bool inCookie;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async => this.token = token;

  @override
  Future<void> clear() async => token = null;
}
