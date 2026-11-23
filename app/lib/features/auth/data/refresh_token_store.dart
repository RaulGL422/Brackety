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

  /// The sign-in of the QR account last used here (`qr-…`): if its session drops, the sign-in
  /// screen offers it again (GR-2). Null to forget it.
  Future<String?> readQrSignIn();

  Future<void> writeQrSignIn(String? signIn);
}

/// The web: the token is in a cookie no script can read. A mark in the browser's storage says
/// one was set, so a reload while the server does not answer keeps the session (and its queue).
class CookieRefreshTokenStore implements RefreshTokenStore {
  const CookieRefreshTokenStore([this._marks]);

  static const _mark = 'brackety.session';
  static const _qrSignIn = 'brackety.qrSignIn';

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

  @override
  Future<String?> readQrSignIn() async => _marks?.read(_qrSignIn);

  @override
  Future<void> writeQrSignIn(String? signIn) async {
    try {
      signIn == null
          ? _marks?.remove(_qrSignIn)
          : _marks?.write(_qrSignIn, signIn);
    } catch (_) {
      // Without it the sign-in screen is just empty, as before.
    }
  }
}

/// Android keystore-backed storage; never shared preferences.
class SecureRefreshTokenStore implements RefreshTokenStore {
  const SecureRefreshTokenStore();

  static const _key = 'refresh_token';
  static const _qrSignInKey = 'qr_sign_in';
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

  @override
  Future<String?> readQrSignIn() => _storage.read(key: _qrSignInKey);

  @override
  Future<void> writeQrSignIn(String? signIn) => signIn == null
      ? _storage.delete(key: _qrSignInKey)
      : _storage.write(key: _qrSignInKey, value: signIn);
}
