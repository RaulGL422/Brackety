import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'offline_store_stub.dart'
    if (dart.library.io) 'offline_store_io.dart'
    as platform;

/// JSON documents kept on the device for the offline queue (no drift for the F1: see
/// docs/decisiones.md). Only the Android app uses it.
abstract interface class OfflineStore {
  /// Null when there is none or it cannot be read.
  Future<Object?> read(String name);

  /// Replaces the whole document at once: a crash never leaves half of it.
  Future<void> write(String name, Object? json);

  /// Deletes every document but the ones named in [keep] (sign-out).
  Future<void> clear({Set<String> keep = const {}});
}

final offlineStoreProvider = Provider<OfflineStore>(
  (ref) => platform.deviceOfflineStore(),
);
