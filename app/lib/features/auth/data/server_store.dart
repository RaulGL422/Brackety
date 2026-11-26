import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The server picked on this device, kept between app starts.
abstract interface class ServerStore {
  Future<String?> read();

  Future<void> write(String url);
}

/// Next to the refresh token, which belongs to this server; the plugin is already there for it.
class SecureServerStore implements ServerStore {
  const SecureServerStore();

  static const _key = 'api_base_url';
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String url) => _storage.write(key: _key, value: url);
}
