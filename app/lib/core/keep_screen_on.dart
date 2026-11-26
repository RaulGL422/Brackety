import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../features/appearance/state/device_prefs_provider.dart';

/// The screen stays on while at least one of these is mounted (the mat board and the
/// scoreboard, one over the other), unless this device turned it off; the web does nothing.
class KeepScreenOn extends ConsumerStatefulWidget {
  const KeepScreenOn({super.key, required this.child});

  final Widget child;

  /// Switches the platform's wake lock; tests replace it.
  @visibleForTesting
  static void Function(bool on) toggle = _platformToggle;

  static var _mounted = 0;

  static void _platformToggle(bool on) {
    if (kIsWeb) return;
    // A phone without the plugin just keeps its usual screen timeout.
    unawaited(WakelockPlus.toggle(enable: on).catchError((Object _) {}));
  }

  @override
  ConsumerState<KeepScreenOn> createState() => _KeepScreenOnState();
}

class _KeepScreenOnState extends ConsumerState<KeepScreenOn> {
  /// Read once: switching the setting takes effect the next time a board opens.
  late final bool _wanted = ref.read(devicePrefsProvider).keepScreenOn;

  @override
  void initState() {
    super.initState();
    if (_wanted && KeepScreenOn._mounted++ == 0) KeepScreenOn.toggle(true);
  }

  @override
  void dispose() {
    if (_wanted && --KeepScreenOn._mounted == 0) KeepScreenOn.toggle(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
