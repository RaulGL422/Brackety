import 'dart:async';
import 'dart:convert';

import '../../../core/storage/browser_storage.dart';
import 'offline_store.dart';

/// The web's documents: one browser storage entry each (`brackety.offline.<name>`), written
/// whole, so a reload or a closed tab never leaves half of one.
class BrowserOfflineStore implements OfflineStore {
  BrowserOfflineStore(this.storage);

  static const prefix = 'brackety.offline.';

  final KeyValueStorage storage;

  @override
  Future<Object?> read(String name) async {
    final text = storage.read('$prefix$name');
    if (text == null) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(String name, Object? json) async {
    try {
      storage.write('$prefix$name', jsonEncode(json));
    } catch (e) {
      // The browser's own error is no Dart exception.
      throw OfflineStoreException(e);
    }
  }

  @override
  Future<void> clear({Set<String> keep = const {}}) async {
    final kept = {for (final name in keep) '$prefix$name'};
    for (final key in storage.keys.toList()) {
      if (key.startsWith(prefix) && !kept.contains(key)) storage.remove(key);
    }
  }
}
