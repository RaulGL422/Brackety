import 'dart:io';

import 'package:brackety/features/auth/state/session_controller.dart';
import 'package:brackety/features/offline/data/offline_store_io.dart';
import 'package:brackety/features/offline/state/offline_sync.dart';
import 'package:brackety/features/scoreboard/data/match_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/offline_fakes.dart';

void main() {
  late TestClock clock;
  late MemoryOfflineStore store;
  late FakeMatchServer server;

  setUp(() {
    clock = TestClock();
    store = MemoryOfflineStore();
    server = FakeMatchServer([serverMatch('m1'), serverMatch('m2')], clock);
  });

  ProviderContainer device() {
    final container = ProviderContainer(
      overrides: offlineOverrides(
        store: store,
        clock: clock,
        repository: server,
      ),
    );
    addTearDown(container.dispose);
    // Signed in before the queue starts listening for sign-outs.
    container.read(sessionProvider);
    return container;
  }

  Future<OfflineSync> open(ProviderContainer container) async {
    final sync = container.read(offlineSyncProvider.notifier);
    await sync.ready;
    await pumpEventQueue();
    for (final id in ['m1', 'm2']) {
      if (container.read(offlineSyncProvider).views[id] == null) {
        await sync.storeView(await server.load(id));
      }
    }
    return sync;
  }

  test(
    'actions wait without network and go out in order when it is back',
    () async {
      final container = device();
      final sync = await open(container);
      server.down = true;

      await sync.enqueue('m1', MatchAction.start);
      clock.advance(const Duration(seconds: 10));
      await sync.enqueue('m1', MatchAction.point, side: Side.red);
      await sync.enqueue('m2', MatchAction.start);
      await pumpEventQueue();

      var state = container.read(offlineSyncProvider);
      expect(state.pendingCount, 3);
      expect(state.connected, isFalse);
      expect(state.ops.map((o) => o.knownEvents), [0, 1, 0]);
      expect(state.local('m1', sync.now())!.view.red.points, 1);
      expect(server.received, isEmpty);
      final queued = [for (final op in state.ops) op.opId];

      server.down = false;
      sync.reportResponse();
      await pumpEventQueue();

      state = container.read(offlineSyncProvider);
      expect(server.received.map((o) => o.opId), queued);
      expect(server.received.map((o) => (o.matchId, o.action)), [
        ('m1', MatchAction.start),
        ('m1', MatchAction.point),
        ('m2', MatchAction.start),
      ]);
      expect(state.pendingCount, 0);
      expect(state.connected, isTrue);
      expect(state.views['m1']!.red.points, 1);
      expect(server.received[1].at, t0.add(const Duration(seconds: 10)));
    },
  );

  test(
    'a lost answer is retried with the same opId and applied once',
    () async {
      final container = device();
      final sync = await open(container);
      server.loseNextAnswer = true;

      await sync.enqueue('m1', MatchAction.start);
      await pumpEventQueue();
      expect(container.read(offlineSyncProvider).pendingCount, 1);

      sync.reportResponse();
      await pumpEventQueue();

      expect(server.received, hasLength(2));
      expect(server.received[0].opId, server.received[1].opId);
      expect(server.views['m1']!.timeline, hasLength(1));
      expect(container.read(offlineSyncProvider).pendingCount, 0);
    },
  );

  test('at is the device time corrected with the last serverTime', () async {
    // The server's clock is 5 s ahead of the device's.
    final serverClock = TestClock(t0.add(const Duration(seconds: 5)));
    server = FakeMatchServer([serverMatch('m1')], serverClock);
    final container = device();
    final sync = container.read(offlineSyncProvider.notifier);
    await sync.storeView(await server.load('m1'));

    await sync.enqueue('m1', MatchAction.start);
    await pumpEventQueue();

    expect(server.received.single.at, t0.add(const Duration(seconds: 5)));
  });

  test(
    'a poll never replaces the view while the match has actions queued',
    () async {
      final container = device();
      final sync = await open(container);
      server.down = true;
      await sync.enqueue('m1', MatchAction.start);
      await pumpEventQueue();
      server.down = false;
      server.writeElsewhere('m1', MatchAction.start);

      await sync.storeView(await server.load('m1'));

      expect(
        container.read(offlineSyncProvider).views['m1']!.timeline,
        isEmpty,
      );
    },
  );

  test(
    'a clash puts the match in review: its actions leave the queue',
    () async {
      final container = device();
      final sync = await open(container);
      server.down = true;
      await sync.enqueue('m1', MatchAction.start);
      await sync.enqueue('m1', MatchAction.point, side: Side.red);
      await sync.enqueue('m2', MatchAction.start);
      server.down = false;
      server.writeElsewhere('m1', MatchAction.start);

      sync.reportResponse();
      await pumpEventQueue();

      final state = container.read(offlineSyncProvider);
      expect(state.ops, isEmpty);
      expect(server.received.map((o) => (o.matchId, o.action)), [
        ('m1', MatchAction.start),
        ('m2', MatchAction.start),
      ]);
      expect(state.views['m1']!.review!.reason, ReviewReason.knownEvents);
      expect(state.local('m1', sync.now())!.view.review, isNotNull);
      expect(state.views['m2']!.status.name, 'inProgress');
    },
  );

  test(
    'once the club decides, the review comes from the view, not the 409',
    () async {
      final container = device();
      final sync = await open(container);
      server.writeElsewhere('m1', MatchAction.start);
      await sync.enqueue('m1', MatchAction.stop);
      await pumpEventQueue();
      expect(
        container.read(offlineSyncProvider).views['m1']!.review,
        isNotNull,
      );

      server.resolveReview('m1');
      await sync.storeView(await server.load('m1'));

      final local = container.read(offlineSyncProvider).local('m1', sync.now());
      expect(local!.view.review, isNull);
    },
  );

  test('another refusal is kept as rejected and other matches go on', () async {
    final container = device();
    final sync = await open(container);
    server.down = true;
    await sync.enqueue('m1', MatchAction.start);
    await sync.enqueue('m1', MatchAction.stop);
    await sync.enqueue('m2', MatchAction.start);
    server.down = false;
    server.nextOpError = httpError(403);

    sync.reportResponse();
    await pumpEventQueue();

    var state = container.read(offlineSyncProvider);
    expect(state.pendingCount, 0);
    expect(state.rejected.map((o) => o.action), [
      MatchAction.start,
      MatchAction.stop,
    ]);
    expect(state.views['m2']!.timeline, hasLength(1));

    await sync.dismissRejected();
    state = container.read(offlineSyncProvider);
    expect(state.ops, isEmpty);
  });

  test(
    'the queue survives closing the app and goes out on the next start',
    () async {
      final first = device();
      final sync = await open(first);
      server.down = true;
      await sync.enqueue('m1', MatchAction.start);
      final opId = first.read(offlineSyncProvider).ops.single.opId;
      first.dispose();

      server.down = false;
      final second = device();
      await second.read(offlineSyncProvider.notifier).ready;
      await pumpEventQueue();

      expect(server.received.single.opId, opId);
      expect(
        second.read(offlineSyncProvider).views['m1']!.timeline,
        hasLength(1),
      );
    },
  );

  test('signing out clears the queue and everything saved', () async {
    final container = device();
    final sync = await open(container);
    server.down = true;
    await sync.enqueue('m1', MatchAction.start);
    await sync.saveBoard('mat1', {'matNumber': 1});
    expect(store.docs, isNotEmpty);

    await container.read(sessionProvider.notifier).logout();
    await pumpEventQueue();

    expect(container.read(offlineSyncProvider).ops, isEmpty);
    expect(container.read(offlineSyncProvider).views, isEmpty);
    expect(store.docs, isEmpty);
  });

  test('the device files are replaced whole and deleted on clear', () async {
    final folder = await Directory.systemTemp.createTemp('brackety-offline');
    addTearDown(() async {
      if (await folder.exists()) await folder.delete(recursive: true);
    });
    final files = FileOfflineStore(
      () async => Directory('${folder.path}${Platform.pathSeparator}offline'),
    );

    await files.write('queue', {'ops': []});
    await files.write('queue', {
      'ops': [1, 2],
    });

    expect(await files.read('queue'), {
      'ops': [1, 2],
    });
    expect(await files.read('missing'), isNull);
    final names = (await Directory(
      '${folder.path}${Platform.pathSeparator}offline',
    ).list().toList()).map((f) => f.uri.pathSegments.last);
    expect(names, ['queue.json']);

    await files.clear();
    expect(await files.read('queue'), isNull);
  });
}
