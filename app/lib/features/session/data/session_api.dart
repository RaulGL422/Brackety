import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// On the web the refresh token travels in an httpOnly cookie and [refreshToken] stays null,
/// so no script can read it.
class SessionTokens {
  const SessionTokens({required this.accessToken, this.refreshToken});

  final String accessToken;
  final String? refreshToken;
}

class SessionApi {
  SessionApi(this._dio);

  final Dio _dio;

  // `X-Client: web` makes the server use the cookie; withCredentials lets the browser send it.
  Options get _options => Options(
    headers: kIsWeb ? const {'X-Client': 'web'} : null,
    extra: const {'withCredentials': true},
  );

  Future<SessionTokens> login(String username, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/login',
      data: {'email': username, 'password': password},
      options: _options,
    );
    return _tokens(response.data!);
  }

  Future<SessionTokens> refresh(String? refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/refresh',
      data: refreshToken == null ? null : {'refreshToken': refreshToken},
      options: _options,
    );
    return _tokens(response.data!);
  }

  Future<void> logout(String? refreshToken) => _dio.post<void>(
    '/api/v1/auth/logout',
    data: refreshToken == null ? null : {'refreshToken': refreshToken},
    options: _options,
  );

  static SessionTokens _tokens(Map<String, dynamic> json) => SessionTokens(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String?,
  );
}
