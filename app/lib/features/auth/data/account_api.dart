import 'package:dio/dio.dart';

import 'account.dart';
import 'registration.dart';

class ReauthToken {
  const ReauthToken(this.token, this.expiresIn);

  final String token;
  final Duration expiresIn;
}

/// Calls to `/api/v1/me`. The sensitive ones take the token of a fresh reauth (`X-Reauth`).
class AccountApi {
  AccountApi(this._dio);

  final Dio _dio;

  static const _base = '/api/v1/me';

  static Options _reauth(String token) => Options(headers: {'X-Reauth': token});

  Future<Account> me() async {
    final response = await _dio.get<Map<String, dynamic>>(_base);
    return Account.fromJson(response.data!);
  }

  Future<Account> updateLocale(String locale) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      _base,
      data: {'locale': locale},
    );
    return Account.fromJson(response.data!);
  }

  Future<void> addProfile(ProfileType type) =>
      _dio.post<void>('$_base/profiles', data: {'type': type.wireName});

  Future<void> removeProfile(ProfileType type) =>
      _dio.delete<void>('$_base/profiles/${type.wireName}');

  Future<ReauthToken> reauth(String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/reauth',
      data: {'password': password},
    );
    final json = response.data!;
    return ReauthToken(
      json['reauthToken'] as String,
      Duration(seconds: (json['expiresIn'] as num).toInt()),
    );
  }

  Future<void> changeEmail(String newEmail, String reauthToken) =>
      _dio.post<void>(
        '$_base/email',
        data: {'newEmail': newEmail},
        options: _reauth(reauthToken),
      );

  /// Returns the day the deletion becomes final.
  Future<DateTime> deleteAccount(String reauthToken) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      _base,
      options: _reauth(reauthToken),
    );
    return DateTime.parse(response.data!['deletesOn'] as String);
  }

  Future<List<int>> export(String reauthToken) async {
    final response = await _dio.get<List<int>>(
      '$_base/export',
      options: _reauth(reauthToken).copyWith(responseType: ResponseType.bytes),
    );
    return response.data!;
  }

  Future<void> unlinkGoogle(String reauthToken) => _dio.delete<void>(
    '$_base/identities/google',
    options: _reauth(reauthToken),
  );

  Future<void> removePassword(String reauthToken) =>
      _dio.delete<void>('$_base/password', options: _reauth(reauthToken));
}
