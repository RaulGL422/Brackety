import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_controller.dart';

/// The device's date, for the client-side age check (the server checks again with its clock).
final todayProvider = Provider<DateTime>((ref) => DateTime.now());

// Email tokens are single-use: no automatic retry, or the retry would always say "invalid".
final verifyEmailProvider = FutureProvider.autoDispose.family<void, String>(
  retry: (_, _) => null,
  (ref, token) async {
    await ref.read(authApiProvider).verifyEmail(token);
    await ref.read(sessionProvider.notifier).emailVerified();
  },
);
