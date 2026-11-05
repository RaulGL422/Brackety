import 'package:brackety/features/auth/state/session_controller.dart';
import 'package:brackety/features/server/data/server_choice.dart';
import 'package:brackety/features/server/state/server_providers.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import 'server_fakes.dart';

void main() {
  ProviderContainer containerFor({
    String? saved,
    bool selectable = true,
    FakeServerStore? store,
    FakeRefreshTokenStore? tokens,
    FakeAuthApi? api,
  }) {
    final container = ProviderContainer(
      overrides: [
        ...sessionOverrides(
          api ?? FakeAuthApi(),
          store: tokens ?? FakeRefreshTokenStore(),
        ),
        serverStoreProvider.overrideWithValue(store ?? FakeServerStore()),
        serverSelectableProvider.overrideWithValue(selectable),
        ...serverOverrides(saved),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('default', () {
    test('without a saved server it is the build API_BASE_URL', () {
      final container = containerFor();

      expect(container.read(serverProvider), apiBaseUrl);
      expect(container.read(dioProvider).options.baseUrl, apiBaseUrl);
    });

    test('the saved server wins over the build one', () {
      final container = containerFor(saved: hallServerUrl);

      expect(container.read(dioProvider).options.baseUrl, hallServerUrl);
    });

    test('the web ignores any saved server', () {
      final container = containerFor(saved: hallServerUrl, selectable: false);

      expect(container.read(serverProvider), apiBaseUrl);
    });
  });

  group('select', () {
    test(
      'saves it, moves every request to it and drops the old tokens',
      () async {
        final store = FakeServerStore();
        final tokens = FakeRefreshTokenStore(token: 'old-server-token');
        final container = containerFor(
          store: store,
          tokens: tokens,
          api: FakeAuthApi(signedIn: true, issueRefreshTokens: true),
        );
        final before = container.read(apiProvider);

        await container.read(serverProvider.notifier).select(hallServerUrl);

        expect(store.url, hallServerUrl);
        expect(tokens.token, isNull);
        expect(container.read(sessionProvider).status, SessionStatus.signedOut);
        expect(container.read(apiProvider), isNot(same(before)));
        expect(container.read(apiProvider).options.baseUrl, hallServerUrl);
      },
    );

    test('the same server keeps everything', () async {
      final store = FakeServerStore();
      final tokens = FakeRefreshTokenStore(token: 'token');
      final container = containerFor(
        saved: hallServerUrl,
        store: store,
        tokens: tokens,
      );

      await container.read(serverProvider.notifier).select(hallServerUrl);

      expect(store.url, isNull);
      expect(tokens.token, 'token');
    });
  });
}
