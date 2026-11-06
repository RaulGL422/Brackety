import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// False while the app is in the background (`paused` or `hidden`): nothing polls the server.
final appInForegroundProvider = NotifierProvider<AppInForeground, bool>(
  AppInForeground.new,
);

class AppInForeground extends Notifier<bool> {
  @override
  bool build() {
    final listener = AppLifecycleListener(
      onStateChange: (s) => state = _foreground(s),
    );
    ref.onDispose(listener.dispose);
    return _foreground(WidgetsBinding.instance.lifecycleState);
  }

  static bool _foreground(AppLifecycleState? s) =>
      s != AppLifecycleState.paused && s != AppLifecycleState.hidden;
}

/// Runs [poll] again [period] after the last one ended, so two never overlap however slow the
/// server is. In the background it waits; back in front it polls at once.
class Poller {
  Poller(this.period, this._poll);

  final Duration period;
  final Future<void> Function() _poll;
  Timer? _timer;
  var _polling = false;
  var _paused = false;
  var _disposed = false;

  void schedule() {
    _timer?.cancel();
    if (_paused || _disposed || _polling) return;
    _timer = Timer(period, _run);
  }

  /// Runs [job] (the first load, say) as a poll: no other one meanwhile, the next after it.
  Future<T> track<T>(Future<T> Function() job) async {
    _timer?.cancel();
    _polling = true;
    try {
      return await job();
    } finally {
      _polling = false;
      schedule();
    }
  }

  Future<void> _run() async {
    if (_polling || _disposed) return;
    await track(_poll);
  }

  void pause() {
    _paused = true;
    _timer?.cancel();
  }

  void resume() {
    if (!_paused) return;
    _paused = false;
    unawaited(_run());
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
  }
}

/// A [Poller] for [ref]'s life that follows the app in and out of the background. It starts
/// with [Poller.track] or [Poller.schedule].
Poller startPolling(Ref ref, Duration period, Future<void> Function() poll) {
  final poller = Poller(period, poll);
  ref.onDispose(poller.dispose);
  if (!ref.read(appInForegroundProvider)) poller.pause();
  ref.listen(
    appInForegroundProvider,
    (_, foreground) => foreground ? poller.resume() : poller.pause(),
  );
  return poller;
}

/// For a provider that is itself the poll: [load] now, and the provider loads again [period]
/// after it ended, only in the foreground (back in front, at once).
Future<T> reloadEvery<T>(
  Ref ref,
  Duration period,
  Future<T> Function() load,
) async {
  Timer? timer;
  var loading = true;
  ref.onDispose(() => timer?.cancel());
  ref.listen(appInForegroundProvider, (_, foreground) {
    timer?.cancel();
    if (foreground && !loading) ref.invalidateSelf();
  });
  try {
    return await load();
  } finally {
    loading = false;
    if (ref.mounted && ref.read(appInForegroundProvider)) {
      timer = Timer(period, ref.invalidateSelf);
    }
  }
}
