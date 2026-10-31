import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'registration.dart';

/// On the web the refresh token travels in an httpOnly cookie and [refreshToken] stays null,
/// so no script can read it.
class SessionTokens {
  const SessionTokens({
    required this.accessToken,
    this.refreshToken,
    required this.emailVerified,
  });

  factory SessionTokens.fromJson(Map<String, dynamic> json) => SessionTokens(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String?,
    emailVerified: json['emailVerified'] as bool,
  );

  final String accessToken;
  final String? refreshToken;
  final bool emailVerified;
}

/// Calls to `/api/v1/auth`, which need no access token.
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  static const _base = '/api/v1/auth';

  // `X-Client: web` makes the server use the cookie; withCredentials lets the browser send it.
  Options get _options => Options(
    headers: kIsWeb ? const {'X-Client': 'web'} : null,
    extra: const {'withCredentials': true},
  );

  Future<SessionTokens> login(String email, String password) =>
      _session('/login', {'email': email, 'password': password});

  Future<SessionTokens> restore(String restoreToken) =>
      _session('/restore', {'restoreToken': restoreToken});

  Future<SessionTokens> refresh(String? refreshToken) =>
      _session('/refresh', _refreshBody(refreshToken));

  Future<void> logout(String? refreshToken) => _dio.post<void>(
    '$_base/logout',
    data: _refreshBody(refreshToken),
    options: _options,
  );

  Future<void> register(Registration registration) =>
      _post('/register', registration.toJson());

  Future<void> verifyEmail(String token) =>
      _post('/email/verify', {'token': token});

  Future<void> resendVerification(String email) =>
      _post('/email/resend', {'email': email});

  Future<void> forgotPassword(String email) =>
      _post('/password/forgot', {'email': email});

  Future<void> resetPassword(String token, String newPassword) =>
      _post('/password/reset', {'token': token, 'newPassword': newPassword});

  Future<SessionTokens> _session(String path, Object? data) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base$path',
      data: data,
      options: _options,
    );
    return SessionTokens.fromJson(response.data!);
  }

  Future<void> _post(String path, Object data) =>
      _dio.post<void>('$_base$path', data: data);

  static Map<String, String>? _refreshBody(String? refreshToken) =>
      refreshToken == null ? null : {'refreshToken': refreshToken};
}
