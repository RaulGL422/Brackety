import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/storage/browser_storage.dart';

/// Where the refresh token lives between app starts.
abstract interface class RefreshTokenStore {
  /// True on the web: the browser keeps it in an httpOnly cookie and this store holds nothing.
  bool get inCookie;

  Future<String?> read();

  Future<void> write(String token);

  Future<void> clear();

  /// Whether the last run ended signed in, so a start without network keeps the session.
  Future<bool> hasSession();
}

/// The web: the token is in a cookie no script can read. A mark in the browser's storage says
/// one was set, so a reload while the server does not answer keeps the session (and its queue).
class CookieRefreshTokenStore implements RefreshTokenStore {
  const CookieRefreshTokenStore([this._marks]);

  static const _mark = 'brackety.session';

  final KeyValueStorage? _marks;

  @override
  bool get inCookie => true;

  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String token) async {
    try {
      _marks?.write(_mark, '1');
    } catch (_) {
      // Without the mark, a reload without network only signs out.
    }
  }

  @override
  Future<void> clear() async => _marks?.remove(_mark);

  @override
  Future<bool> hasSession() async => _marks?.read(_mark) != null;
}

/// Android keystore-backed storage; never shared preferences.
class SecureRefreshTokenStore implements RefreshTokenStore {
  const SecureRefreshTokenStore();

  static const _key = 'refresh_token';
  static const _storage = FlutterSecureStorage();

  @override
  bool get inCookie => false;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);

  @override
  Future<bool> hasSession() async => await read() != null;
}
