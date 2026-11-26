import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// How many finished events «Mis eventos» lists.
enum FinishedShown { latest, all, none }

/// What this device prefers (Raul, 2026-11-26): each phone or computer its own, like the theme.
class DevicePrefs {
  const DevicePrefs({
    this.textScale,
    this.moreContrast = false,
    this.finished = FinishedShown.latest,
    this.bell = true,
    this.vibrate = true,
    this.keepScreenOn = true,
  });

  factory DevicePrefs.fromJson(Map<String, dynamic> json) => DevicePrefs(
    textScale: textScales.contains(json['textScale'])
        ? (json['textScale'] as num).toDouble()
        : null,
    moreContrast: json['moreContrast'] == true,
    finished:
        FinishedShown.values.asNameMap()[json['finished']] ??
        FinishedShown.latest,
    bell: json['bell'] != false,
    vibrate: json['vibrate'] != false,
    keepScreenOn: json['keepScreenOn'] != false,
  );

  /// The sizes on offer; null follows the device's own setting.
  static const textScales = [1.0, 1.25, 1.5, 2.0];

  final double? textScale;

  /// Grey text turns black and outlines darker: for strong sun or poor sight.
  final bool moreContrast;
  final FinishedShown finished;

  /// The scoreboard's bells: start, ten seconds left, end.
  final bool bell;

  /// A buzz with the end bell, where the device can.
  final bool vibrate;

  /// The scoreboard and the mat board keep the screen on while open.
  final bool keepScreenOn;

  DevicePrefs copyWith({
    bool? moreContrast,
    FinishedShown? finished,
    bool? bell,
    bool? vibrate,
    bool? keepScreenOn,
  }) => DevicePrefs(
    textScale: textScale,
    moreContrast: moreContrast ?? this.moreContrast,
    finished: finished ?? this.finished,
    bell: bell ?? this.bell,
    vibrate: vibrate ?? this.vibrate,
    keepScreenOn: keepScreenOn ?? this.keepScreenOn,
  );

  /// Null goes back to the device's size.
  DevicePrefs withTextScale(double? scale) => DevicePrefs(
    textScale: scale,
    moreContrast: moreContrast,
    finished: finished,
    bell: bell,
    vibrate: vibrate,
    keepScreenOn: keepScreenOn,
  );

  Map<String, dynamic> toJson() => {
    'textScale': ?textScale,
    'moreContrast': moreContrast,
    'finished': finished.name,
    'bell': bell,
    'vibrate': vibrate,
    'keepScreenOn': keepScreenOn,
  };
}

abstract interface class DevicePrefsStore {
  Future<DevicePrefs> read();

  Future<void> write(DevicePrefs prefs);
}

/// Next to the theme, in the storage the session already uses.
class SecureDevicePrefsStore implements DevicePrefsStore {
  const SecureDevicePrefsStore();

  static const _key = 'device_prefs';
  static const _storage = FlutterSecureStorage();

  @override
  Future<DevicePrefs> read() async {
    final saved = await _storage.read(key: _key);
    if (saved == null) return const DevicePrefs();
    try {
      return DevicePrefs.fromJson(jsonDecode(saved) as Map<String, dynamic>);
    } on FormatException {
      // Unreadable (an older or damaged value): the defaults, as on a new device.
      return const DevicePrefs();
    }
  }

  @override
  Future<void> write(DevicePrefs prefs) =>
      _storage.write(key: _key, value: jsonEncode(prefs.toJson()));
}
