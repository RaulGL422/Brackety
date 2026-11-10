import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// The screen stays on while at least one of these is mounted (the mat board and the
/// scoreboard, one over the other); the web does nothing.
class KeepScreenOn extends StatefulWidget {
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
  State<KeepScreenOn> createState() => _KeepScreenOnState();
}

class _KeepScreenOnState extends State<KeepScreenOn> {
  @override
  void initState() {
    super.initState();
    if (KeepScreenOn._mounted++ == 0) KeepScreenOn.toggle(true);
  }

  @override
  void dispose() {
    if (--KeepScreenOn._mounted == 0) KeepScreenOn.toggle(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
