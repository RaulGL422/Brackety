import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/admin_session.dart';
import '../data/debug_api.dart';

final debugApiProvider = Provider<DebugApi>(
  (ref) => DebugApi(ref.watch(adminDioProvider)),
);

// No automatic retry: the screen shows the error with its own retry button.
final scenariosProvider = FutureProvider.autoDispose<List<Scenario>>(
  retry: (_, _) => null,
  (ref) => ref.watch(debugApiProvider).scenarios(),
);

final snapshotsProvider = FutureProvider.autoDispose<List<Snapshot>>(
  retry: (_, _) => null,
  (ref) => ref.watch(debugApiProvider).snapshots(),
);
