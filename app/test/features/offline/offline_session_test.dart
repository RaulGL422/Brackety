import 'package:brackety/features/auth/state/session_controller.dart';
import 'package:brackety/features/mat/data/mat_board.dart';
import 'package:brackety/features/offline/state/offline_sync.dart';
import 'package:brackety/features/scoreboard/data/match_view.dart';
import 'package:brackety/features/server/state/server_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/offline_fakes.dart';
import '../server/server_fakes.dart';

const _owner = 'referee-a@test.local';
const _other = 'referee-b@test.local';

void main() {
  late TestClock clock;
  late MemoryOfflineStore store;
  late FakeMatchServer server;
  late FakeAuthApi auth;

  setUp(() {
    clock = TestClock();
    store = MemoryOfflineStore();
    server = FakeMatchServer([serverMatch('m1'), serverMatch('m2')], clock);
    auth = FakeAuthApi(signedIn: true, jwt: true)..subject = _owner;
  });

  ProviderContainer device() {
    final container = ProviderContainer(
      overrides: [
        ...offlineOverrides(
          store: store,
          clock: clock,
          repository: server,
          auth: auth,
        ),
        ...serverOverrides(null),
        serverStoreProvider.overrideWithValue(FakeServerStore()),
      ],
    );
    addTearDown(container.dispose);
    container.read(sessionProvider);
    return container;
  }

  OfflineState offline(ProviderContainer c) => c.read(offlineSyncProvider);

  /// Signed in as [_owner] with one action of m1 waiting for the network.
  Future<ProviderContainer> withQueue() async {
    final container = device();
    final sync = container.read(offlineSyncProvider.notifier);
    await sync.ready;
    await pumpEventQueue();
    await sync.storeView(await server.load('m1'));
    server.down = true;
    await sync.enqueue('m1', MatchAction.start);
    await sync.saveBoard('mat1', {'matNumber': 1});
    return container;
  }

  /// The server says no to the next refresh, as with an expired session.
  Future<void> rejectSession(ProviderContainer container) async {
    auth.signedIn = false;
    await container.read(sessionProvider.notifier).refresh();
    await pumpEventQueue();
  }

  Future<void> login(ProviderContainer container, String email) async {
    await container.read(sessionProvider.notifier).login(email, email);
    await pumpEventQueue();
  }

  test('a rejected session keeps the queue and forgets the views', () async {
    final container = await withQueue();

    await rejectSession(container);

    expect(container.read(sessionProvider).expired, isTrue);
    expect(offline(container).ops, isEmpty);
    expect(offline(container).hidden, hasLength(1));
    expect(offline(container).views, isEmpty);
    expect(store.docs.keys, ['queue']);
    final saved = (store.docs['queue']! as Map)['ops'] as List;
    expect((saved.single as Map)['account'], _owner);
  });

  test('the same account back sends its queue', () async {
    final container = await withQueue();
    await rejectSession(container);
    server.down = false;

    await login(container, _owner);

    expect(server.received.map((op) => op.action), [MatchAction.start]);
    expect(offline(container).ops, isEmpty);
    expect(offline(container).hidden, isEmpty);
    expect(offline(container).views['m1']!.status, isNot(MatchStatus.pending));
  });

  test(
    'another account neither sees nor sends it, and its sign-out keeps it',
    () async {
      final container = await withQueue();
      await rejectSession(container);
      server.down = false;

      await login(container, _other);
      expect(offline(container).pendingCount, 0);
      expect(offline(container).pendingFor('m1'), isEmpty);
      expect(server.received, isEmpty);

      await container.read(sessionProvider.notifier).logout();
      await pumpEventQueue();
      expect(offline(container).hidden, hasLength(1));
      expect(store.docs.keys, ['queue']);

      await login(container, _owner);
      expect(server.received, hasLength(1));
    },
  );

  test('the owner signing out by hand deletes it', () async {
    final container = await withQueue();
    await rejectSession(container);
    // Still without network for the scoreboard: the action waits again, now shown.
    await login(container, _owner);
    expect(offline(container).pendingCount, 1);

    await container.read(sessionProvider.notifier).logout();
    await pumpEventQueue();

    expect(offline(container).ops, isEmpty);
    expect(offline(container).hidden, isEmpty);
    expect(store.docs, isEmpty);
  });

  test('another server deletes a kept queue', () async {
    final container = await withQueue();
    await rejectSession(container);

    await container.read(serverProvider.notifier).select('https://other.test');
    await pumpEventQueue();

    expect(offline(container).hidden, isEmpty);
    expect(store.docs, isEmpty);
  });

  test('a queue saved without account goes to the one that enters', () async {
    await server.load('m1');
    store.docs['queue'] = {
      'ops': [
        {
          'type': 'START',
          'side': null,
          'reason': null,
          'opId': 'old-op',
          'at': t0.toIso8601String(),
          'knownEvents': 0,
          'matchId': 'm1',
          'rejected': false,
        },
      ],
      'heldForReview': <String>[],
    };
    auth.signedIn = false;
    final container = device();
    await container.read(offlineSyncProvider.notifier).ready;
    await pumpEventQueue();
    expect(offline(container).hidden, hasLength(1));

    await login(container, _other);

    expect(server.received.single.opId, 'old-op');
    expect(server.received.single.account, _other);
  });
}
