import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/browser_storage.dart';
import 'offline_store_browser.dart';
import 'offline_store_stub.dart'
    if (dart.library.io) 'offline_store_io.dart'
    as platform;

/// JSON documents kept on the device for the offline queue (no drift for the F1: see
/// docs/decisiones.md): files on Android, browser storage on the web.
abstract interface class OfflineStore {
  /// Null when there is none or it cannot be read.
  Future<Object?> read(String name);

  /// Replaces the whole document at once: a crash never leaves half of it.
  Future<void> write(String name, Object? json);

  /// Deletes every document but the ones named in [keep] (sign-out).
  Future<void> clear({Set<String> keep = const {}});
}

/// The store could not write (the browser's storage is full or blocked).
class OfflineStoreException implements Exception {
  const OfflineStoreException(this.cause);

  final Object cause;

  @override
  String toString() => 'OfflineStoreException: $cause';
}

final offlineStoreProvider = Provider<OfflineStore>((ref) {
  final browser = ref.watch(browserStorageProvider);
  return browser != null
      ? BrowserOfflineStore(browser)
      : platform.deviceOfflineStore();
});
