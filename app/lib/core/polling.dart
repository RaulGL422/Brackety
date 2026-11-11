import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'live/live_connection.dart';

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

/// Without the live socket, how often screens fetch again on their own.
const liveFallback = Duration(seconds: 20);

/// With the socket up, a slow safety net in case a signal was lost.
const liveSafety = Duration(seconds: 60);

/// A busy event sends signals in bursts: at most one fetch per screen this often.
const liveMinGap = Duration(seconds: 1);

/// Runs [poll] again [period] after the last one ended, so two never overlap however slow the
/// server is. In the background it waits; back in front it polls at once. [pollNow] (a change
/// on the server) polls at once, or once more right after the one running. When [quiet] says
/// so (the live socket is up and the last poll is recent), a period passes without a poll.
class Poller {
  Poller(this.period, this._poll, {this.quiet});

  final Duration period;
  final Future<void> Function() _poll;
  final bool Function(Duration sinceLastPoll)? quiet;
  final _sinceLast = Stopwatch()..start();
  Timer? _timer;
  var _polling = false;
  var _again = false;
  var _paused = false;
  var _disposed = false;

  void schedule() {
    _timer?.cancel();
    if (_paused || _disposed || _polling) return;
    _timer = Timer(period, () {
      if (quiet?.call(_sinceLast.elapsed) ?? false) {
        schedule();
      } else {
        unawaited(_run());
      }
    });
  }

  /// Runs [job] (the first load, say) as a poll: no other one meanwhile, the next after it.
  Future<T> track<T>(Future<T> Function() job) async {
    _timer?.cancel();
    _polling = true;
    try {
      return await job();
    } finally {
      _polling = false;
      _sinceLast.reset();
      if (_again && !_paused && !_disposed) {
        _again = false;
        unawaited(_run());
      } else {
        schedule();
      }
    }
  }

  void pollNow() {
    if (_paused || _disposed) return;
    if (_polling) {
      _again = true;
      return;
    }
    unawaited(_run());
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

/// A [Poller] for [ref]'s life that follows the app in and out of the background and polls at
/// once when [topics] change on the server (docs/modulos/tiempo-real.md). It starts with
/// [Poller.track] or [Poller.schedule].
Poller startLivePolling(
  Ref ref,
  Set<String> topics,
  Future<void> Function() poll,
) {
  late final LiveFollow follow;
  final poller = Poller(
    liveFallback,
    poll,
    quiet: (since) => follow.connected && since < liveSafety,
  );
  follow = ref.read(liveConnectionProvider).follow(topics, poller.pollNow);
  ref.onDispose(() {
    poller.dispose();
    follow.cancel();
  });
  if (!ref.read(appInForegroundProvider)) poller.pause();
  ref.listen(
    appInForegroundProvider,
    (_, foreground) => foreground ? poller.resume() : poller.pause(),
  );
  return poller;
}

/// For a provider that is itself the fetch: [load] now, and again when [topics] change on the
/// server (at most once per [liveMinGap]) or, as a safety net, after [liveFallback] with the
/// socket down or [liveSafety] with it up. Only in the foreground; back in front, at once.
Future<T> liveReload<T>(
  Ref ref,
  Set<String> topics,
  Future<T> Function() load,
) async {
  Timer? fallback;
  Timer? soon;
  var loading = true;
  var again = false;
  final since = Stopwatch()..start();
  void reload() {
    if (!ref.mounted || !ref.read(appInForegroundProvider)) return;
    if (loading) {
      again = true;
      return;
    }
    if (soon != null) return;
    final wait = liveMinGap - since.elapsed;
    soon = Timer(wait.isNegative ? Duration.zero : wait, ref.invalidateSelf);
  }

  final follow = ref.read(liveConnectionProvider).follow(topics, reload);
  ref.onDispose(() {
    fallback?.cancel();
    soon?.cancel();
    follow.cancel();
  });
  ref.listen(appInForegroundProvider, (_, foreground) {
    fallback?.cancel();
    if (foreground && !loading) ref.invalidateSelf();
  });
  try {
    return await load();
  } finally {
    loading = false;
    if (ref.mounted) {
      if (again) {
        reload();
      } else if (ref.read(appInForegroundProvider)) {
        void tick() {
          if (follow.connected && since.elapsed < liveSafety) {
            fallback = Timer(liveFallback, tick);
          } else {
            ref.invalidateSelf();
          }
        }

        fallback = Timer(liveFallback, tick);
      }
    }
  }
}
