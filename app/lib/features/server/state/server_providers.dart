import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../auth/state/session_controller.dart';
import '../data/server_store.dart';

/// Only the Android app picks its server; the web talks to the one it was built for (or came from).
final serverSelectableProvider = Provider<bool>((ref) => !kIsWeb);

final serverStoreProvider = Provider<ServerStore>(
  (ref) => const SecureServerStore(),
);

/// What [ServerStore] held at start-up, read in `main` before the first request.
final savedServerProvider = Provider<String?>((ref) => null);

final serverProvider = NotifierProvider<ServerController, String>(
  ServerController.new,
);

/// The server the app talks to: the saved one, or the build's `API_BASE_URL`.
class ServerController extends Notifier<String> {
  @override
  String build() {
    final saved = ref.watch(savedServerProvider);
    return ref.watch(serverSelectableProvider) && saved != null
        ? saved
        : apiBaseUrl;
  }

  /// Only from the sign-in screen. Stored tokens are from the old server: they go first.
  Future<void> select(String url) async {
    if (url == state) return;
    await ref.read(sessionProvider.notifier).sessionsClosed();
    await ref.read(serverStoreProvider).write(url);
    state = url;
  }
}

/// Makes every request follow [serverProvider]; [saved] as read from [ServerStore].
List<Override> serverOverrides(String? saved) => [
  savedServerProvider.overrideWithValue(saved),
  apiBaseUrlProvider.overrideWith((ref) => ref.watch(serverProvider)),
];
