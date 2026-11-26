import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/device_prefs.dart';

final devicePrefsStoreProvider = Provider<DevicePrefsStore>(
  (ref) => const SecureDevicePrefsStore(),
);

/// What [DevicePrefsStore] held at start-up, read in `main` so the first frame is already right.
final savedDevicePrefsProvider = Provider<DevicePrefs>(
  (ref) => const DevicePrefs(),
);

final devicePrefsProvider =
    NotifierProvider<DevicePrefsController, DevicePrefs>(
      DevicePrefsController.new,
    );

class DevicePrefsController extends Notifier<DevicePrefs> {
  @override
  DevicePrefs build() => ref.watch(savedDevicePrefsProvider);

  Future<void> change(DevicePrefs Function(DevicePrefs) update) async {
    state = update(state);
    await ref.read(devicePrefsStoreProvider).write(state);
  }
}
