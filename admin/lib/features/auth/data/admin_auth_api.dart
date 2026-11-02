import 'package:dio/dio.dart';

/// Superadmin sign-in. It has no refresh: the token lasts [expiresIn] seconds (1 h) and then
/// the next call answers 401.
class AdminAuthApi {
  AdminAuthApi(this._dio);

  final Dio _dio;

  Future<String> login(String email, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/admin/auth/login',
      data: {'email': email, 'password': password},
    );
    return response.data!['accessToken'] as String;
  }
}
