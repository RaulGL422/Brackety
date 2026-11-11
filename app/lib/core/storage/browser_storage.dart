import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'browser_storage_stub.dart'
    if (dart.library.js_interop) 'browser_storage_web.dart'
    as platform;

/// Text the browser keeps across reloads and closed tabs (`localStorage`). Only on the web.
abstract interface class KeyValueStorage {
  String? read(String key);

  /// Throws if the browser refuses (storage full or blocked).
  void write(String key, String value);

  void remove(String key);

  Iterable<String> get keys;
}

/// Null outside the web, or when the browser blocks storage.
final browserStorageProvider = Provider<KeyValueStorage?>(
  (ref) => platform.browserStorage(),
);
