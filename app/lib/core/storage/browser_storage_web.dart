import 'package:web/web.dart' as web;

import 'browser_storage.dart';

KeyValueStorage? browserStorage() {
  try {
    return _LocalStorage(web.window.localStorage);
  } catch (_) {
    // Blocked by the browser's privacy settings: the app works, only without keeping anything.
    return null;
  }
}

class _LocalStorage implements KeyValueStorage {
  _LocalStorage(this._storage);

  final web.Storage _storage;

  @override
  String? read(String key) => _storage.getItem(key);

  @override
  void write(String key, String value) => _storage.setItem(key, value);

  @override
  void remove(String key) => _storage.removeItem(key);

  @override
  Iterable<String> get keys => [
    for (var i = 0; i < _storage.length; i++) ?_storage.key(i),
  ];
}
