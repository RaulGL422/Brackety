import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the refresh token lives between app starts.
abstract interface class RefreshTokenStore {
  /// True on the web: the browser keeps it in an httpOnly cookie and this store holds nothing.
  bool get inCookie;

  Future<String?> read();

  Future<void> write(String token);

  Future<void> clear();
}

class CookieRefreshTokenStore implements RefreshTokenStore {
  const CookieRefreshTokenStore();

  @override
  bool get inCookie => true;

  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String token) async {}

  @override
  Future<void> clear() async {}
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
}
