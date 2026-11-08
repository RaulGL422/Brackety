import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The light or dark choice made on this device, kept between app starts.
abstract interface class ThemeStore {
  Future<ThemeMode> read();

  Future<void> write(ThemeMode mode);
}

/// The plugin is already there for the session; a choice this small needs no other.
class SecureThemeStore implements ThemeStore {
  const SecureThemeStore();

  static const _key = 'theme_mode';
  static const _storage = FlutterSecureStorage();

  @override
  Future<ThemeMode> read() async {
    final saved = await _storage.read(key: _key);
    return ThemeMode.values.asNameMap()[saved] ?? ThemeMode.system;
  }

  @override
  Future<void> write(ThemeMode mode) =>
      _storage.write(key: _key, value: mode.name);
}
