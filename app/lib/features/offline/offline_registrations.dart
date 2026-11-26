import 'package:flutter_riverpod/misc.dart';

import '../auth/state/session_controller.dart';
import '../auth/ui/confirm_sign_out.dart';
import 'data/offline_get_cache.dart';
import 'state/offline_sync.dart';

/// What offline gives the features below it, which do not know it: the saved copy of the lists on
/// every API call and the queue's count before signing out. `main` registers them.
List<Override> offlineRegistrations() => [
  apiInterceptorsProvider.overrideWith((ref) => [OfflineGetCache(ref)]),
  pendingActionsProvider.overrideWith(
    (ref) => ref.watch(offlineSyncProvider).pendingCount,
  ),
];
