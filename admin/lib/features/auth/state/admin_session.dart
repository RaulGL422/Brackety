import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_auth_api.dart';

/// The token lives only here, in memory: a reload or a closed tab means signing in again.
class AdminSession {
  const AdminSession({this.token, this.expired = false});

  final String? token;

  /// Signed out because the server rejected the token, for the sign-in screen to explain.
  final bool expired;

  bool get signedIn => token != null;
}

final adminAuthApiProvider = Provider<AdminAuthApi>(
  (ref) => AdminAuthApi(ref.watch(dioProvider)),
);

final adminSessionProvider =
    NotifierProvider<AdminSessionController, AdminSession>(
      AdminSessionController.new,
    );

class AdminSessionController extends Notifier<AdminSession> {
  @override
  AdminSession build() => const AdminSession();

  Future<void> login(String email, String password) async {
    final token = await ref
        .read(adminAuthApiProvider)
        .login(email.trim(), password);
    state = AdminSession(token: token);
  }

  void logout() => state = const AdminSession();

  /// A 401 for [token]. One sent before a new sign-in must not end the new session.
  void expired(String token) {
    if (state.token == token) state = const AdminSession(expired: true);
  }
}

/// Dio for the admin API with the superadmin token; any 401 ends the session.
final adminDioProvider = Provider<Dio>((ref) {
  final base = ref.watch(dioProvider);
  // Shares the base connection pool; dioProvider closes it.
  final dio = Dio(base.options)..httpClientAdapter = base.httpClientAdapter;
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(adminSessionProvider).token;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        final sent = error.requestOptions.headers['Authorization'];
        if (error.response?.statusCode == 401 && sent is String) {
          ref
              .read(adminSessionProvider.notifier)
              .expired(sent.substring('Bearer '.length));
        }
        handler.next(error);
      },
    ),
  );
  return dio;
});
