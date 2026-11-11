import 'dart:async';
import 'dart:convert';

import 'package:brackety/core/live/live_connection.dart';
import 'package:brackety/features/auth/data/account.dart';
import 'package:brackety/features/auth/data/account_api.dart';
import 'package:brackety/features/auth/data/auth_api.dart';
import 'package:brackety/features/auth/data/refresh_token_store.dart';
import 'package:brackety/features/auth/data/registration.dart';
import 'package:brackety/features/auth/state/session_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/misc.dart';

import 'live_fakes.dart';

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

/// An unsigned JWT with [subject] as its `sub`; [n] tells sessions apart.
String fakeJwt(String subject, [int n = 1]) {
  String part(Object json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'none'})}.${part({'sub': subject, 'n': n})}.sig';
}

/// No answer at all: no network or a timeout.
DioException networkError() => DioException.connectionError(
  requestOptions: RequestOptions(),
  reason: 'offline',
);

/// The provider overrides every app test needs: [api] instead of the server and a web-like
/// cookie store, so the session restores itself when [FakeAuthApi.signedIn] is true. `/me`
/// answers from [account] (a default one when not given). The live socket never answers
/// unless a test brings its own ([live], e.g. a [FakeLiveServer]).
List<Override> sessionOverrides(
  FakeAuthApi api, {
  RefreshTokenStore store = const CookieRefreshTokenStore(),
  FakeAccountApi? account,
  LiveSocketConnect? live,
}) => [
  authApiProvider.overrideWithValue(api),
  refreshTokenStoreProvider.overrideWithValue(store),
  accountApiProvider.overrideWithValue(account ?? FakeAccountApi()),
  liveSocketConnectProvider.overrideWithValue(live ?? silentLive),
];

/// Server auth without a server. Sign-in works for [accounts] and when the password equals the
/// email (like the demo accounts); each `...Error` makes that call fail instead.
class FakeAuthApi implements AuthApi {
  FakeAuthApi({
    this.signedIn = false,
    this.issueRefreshTokens = false,
    this.jwt = false,
  });

  bool signedIn;

  /// Android answers carry the refresh token; web answers do not.
  final bool issueRefreshTokens;

  /// Access tokens as JWTs whose `sub` is [subject], instead of `access-<n>`.
  final bool jwt;

  /// The account signed in; the email of the last login.
  String subject = 'referee@test.local';
  bool emailVerified = true;

  DioException? loginError;
  DioException? restoreError;
  DioException? refreshError;
  DioException? registerError;
  DioException? verifyError;
  DioException? forgotError;
  DioException? resetError;
  DioException? resetCheckError;
  DioException? confirmEmailChangeError;

  /// Email → password; registering adds to it unless the email is already there.
  final accounts = <String, String>{};

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
  final resetChecks = <String>[];
  final emailChanges = <String>[];
  int _sessions = 0;

  SessionTokens _session() {
    _sessions++;
    signedIn = true;
    return SessionTokens(
      accessToken: jwt ? fakeJwt(subject, _sessions) : 'access-$_sessions',
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
    if (email != password && accounts[email] != password) {
      throw httpError(401);
    }
    logins.add(email);
    subject = email;
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
    accounts.putIfAbsent(registration.email, () => registration.password);
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
  Future<void> confirmEmailChange(String token) async {
    _failWith(confirmEmailChangeError);
    emailChanges.add(token);
    signedIn = false;
  }

  @override
  Future<void> forgotPassword(String email) async {
    _failWith(forgotError);
    forgotten.add(email);
  }

  @override
  Future<void> checkResetToken(String token) async {
    resetChecks.add(token);
    _failWith(resetCheckError);
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

  /// The web's mark of a session (see [CookieRefreshTokenStore]).
  bool marked = false;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async {
    marked = true;
    this.token = token;
  }

  @override
  Future<void> clear() async {
    marked = false;
    token = null;
  }

  @override
  Future<bool> hasSession() async => inCookie ? marked : token != null;
}

/// `/api/v1/me` without a server, starting from [account]. The password is [password]; each
/// `...Error` makes that call fail instead (a list fails one call per element, then works).
class FakeAccountApi implements AccountApi {
  FakeAccountApi({Account? account, this.password = 'secret-password'})
    : account = account ?? testAccount();

  Account account;
  final String password;

  DioException? meError;
  DioException? localeError;
  final addProfileErrors = <DioException>[];
  DioException? removeProfileError;
  final actionErrors = <DioException>[];
  DioException? reauthError;
  DateTime deletesOn = DateTime(2026, 12, 2);

  int meCalls = 0;
  final locales = <String>[];
  final addedProfiles = <ProfileType>[];
  final removedProfiles = <ProfileType>[];
  final reauths = <String>[];

  /// Sensitive call name → the reauth token it carried.
  final actions = <(String, String)>[];
  int _tokens = 0;

  @override
  Future<Account> me() async {
    meCalls++;
    if (meError case final error?) throw error;
    return account;
  }

  @override
  Future<Account> updateLocale(String locale) async {
    if (localeError case final error?) throw error;
    locales.add(locale);
    return account = account.withLocale(locale);
  }

  @override
  Future<void> addProfile(ProfileType type) async {
    if (addProfileErrors.isNotEmpty) throw addProfileErrors.removeAt(0);
    addedProfiles.add(type);
    account = _withProfiles([...account.profiles, AccountProfile(type: type)]);
  }

  @override
  Future<void> removeProfile(ProfileType type) async {
    if (removeProfileError case final error?) throw error;
    removedProfiles.add(type);
    account = _withProfiles([
      for (final profile in account.profiles)
        if (profile.type != type) profile,
    ]);
  }

  @override
  Future<ReauthToken> reauth(String password) async {
    reauths.add(password);
    if (reauthError case final error?) throw error;
    if (password != this.password) {
      throw httpError(403, body: {'code': 'REAUTH_FAILED'});
    }
    _tokens++;
    return ReauthToken('reauth-$_tokens', const Duration(minutes: 5));
  }

  Future<void> _sensitive(String name, String token) async {
    actions.add((name, token));
    if (actionErrors.isNotEmpty) throw actionErrors.removeAt(0);
  }

  @override
  Future<void> changeEmail(String newEmail, String reauthToken) =>
      _sensitive('email:$newEmail', reauthToken);

  @override
  Future<DateTime> deleteAccount(String reauthToken) async {
    await _sensitive('delete', reauthToken);
    return deletesOn;
  }

  @override
  Future<List<int>> export(String reauthToken) async {
    await _sensitive('export', reauthToken);
    return utf8.encode('{"email":"${account.email}"}');
  }

  @override
  Future<void> unlinkGoogle(String reauthToken) async {
    await _sensitive('unlinkGoogle', reauthToken);
    account = Account(
      email: account.email,
      emailVerified: account.emailVerified,
      locale: account.locale,
      profiles: account.profiles,
      signInMethods: [
        for (final method in account.signInMethods)
          if (method.method != SignInMethod.google) method,
      ],
    );
  }

  @override
  Future<void> removePassword(String reauthToken) =>
      _sensitive('removePassword', reauthToken);

  Account _withProfiles(List<AccountProfile> profiles) => Account(
    email: account.email,
    emailVerified: account.emailVerified,
    locale: account.locale,
    profiles: profiles,
    signInMethods: account.signInMethods,
  );
}

/// A helper with a password, in English unless [locale] says otherwise.
Account testAccount({
  String email = 'ana@example.com',
  bool emailVerified = true,
  String locale = 'en',
  List<AccountProfile> profiles = const [
    AccountProfile(type: ProfileType.helper),
  ],
  List<SignInMethod> signInMethods = const [
    SignInMethod(method: SignInMethod.password),
  ],
}) => Account(
  email: email,
  emailVerified: emailVerified,
  locale: locale,
  profiles: profiles,
  signInMethods: signInMethods,
);
