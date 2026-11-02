import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/admin_session.dart';
import '../data/locks_api.dart';

final locksApiProvider = Provider<LocksApi>(
  (ref) => LocksApi(ref.watch(adminDioProvider)),
);

enum RevokeResult { revoked, alreadyExpired }

// No automatic retry: the screen shows the error with its own retry button.
final locksProvider =
    AsyncNotifierProvider.autoDispose<LocksController, List<Lock>>(
      LocksController.new,
      retry: (_, _) => null,
    );

class LocksController extends AsyncNotifier<List<Lock>> {
  @override
  Future<List<Lock>> build() => ref.read(locksApiProvider).list();

  void refresh() => ref.invalidateSelf();

  /// A 404 means it expired meanwhile: the list is reloaded. Other failures are thrown.
  Future<RevokeResult> revoke(String lockId) async {
    try {
      await ref.read(locksApiProvider).revoke(lockId);
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
      if (ref.mounted) ref.invalidateSelf();
      return RevokeResult.alreadyExpired;
    }
    final locks = state.value;
    if (ref.mounted && locks != null) {
      state = AsyncData([
        for (final lock in locks)
          if (lock.lockId != lockId) lock,
      ]);
    }
    return RevokeResult.revoked;
  }
}
