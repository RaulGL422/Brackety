import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_controller.dart';

/// The device's date, for the client-side age check (the server checks again with its clock).
final todayProvider = Provider<DateTime>((ref) => DateTime.now());

/// `APP_ENV=dev`, as a provider so tests can switch it.
final devEnvironmentProvider = Provider<bool>((ref) => isDevEnvironment);

// Email tokens are single-use: no automatic retry, or the retry would always say "invalid".
final verifyEmailProvider = FutureProvider.autoDispose.family<void, String>(
  retry: (_, _) => null,
  (ref, token) async {
    await ref.read(authApiProvider).verifyEmail(token);
    await ref.read(sessionProvider.notifier).emailVerified();
  },
);

/// Whether a reset link still works, checked on open. Only the server's 400 says no: without an
/// answer the form shows anyway and the submit tells.
final resetLinkValidProvider = FutureProvider.autoDispose.family<bool, String>(
  retry: (_, _) => null,
  (ref, token) async {
    try {
      await ref.read(authApiProvider).checkResetToken(token);
      return true;
    } on DioException catch (e) {
      return e.response?.statusCode != 400;
    }
  },
);
