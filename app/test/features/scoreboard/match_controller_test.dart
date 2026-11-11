import 'dart:async';

import 'package:brackety/features/auth/state/session_controller.dart';
import 'package:brackety/features/mat/data/mat_board.dart';
import 'package:brackety/features/offline/data/offline_store.dart';
import 'package:brackety/features/offline/state/offline_sync.dart';
import 'package:brackety/features/scoreboard/data/match_view.dart';
import 'package:brackety/features/scoreboard/data/scoreboard_repository.dart';
import 'package:brackety/features/scoreboard/data/tambo_match.dart';
import 'package:brackety/features/scoreboard/state/bell.dart';
import 'package:brackety/features/scoreboard/state/match_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/match_fakes.dart';
import '../../support/offline_fakes.dart';

// The referee's match goes through the device's queue on Android and on the web alike.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeBell bell;
  late FakeScoreboardRepository repository;
  late ProviderContainer container;

  setUp(() {
    bell = FakeBell();
    repository = FakeScoreboardRepository(matchView());
    container = ProviderContainer(
      overrides: [
        ...sessionOverrides(FakeAuthApi(signedIn: true)),
        offlineStoreProvider.overrideWithValue(MemoryOfflineStore()),
        deviceClockProvider.overrideWithValue(
          () => DateTime(2027, 3, 10, 10, 0, 30),
        ),
        bellProvider.overrideWithValue(bell),
        scoreboardRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    container.read(sessionProvider);
  });

  Future<MatchController> load() async {
    final subscription = container.listen(
      matchControllerProvider('m1'),
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(matchControllerProvider('m1').future);
    return container.read(matchControllerProvider('m1').notifier);
  }

  MatchView? shown() => container.read(matchControllerProvider('m1')).value;

  test('the clock counts down locally only while running', () async {
    repository.current = matchView(
      status: MatchStatus.inProgress,
      remaining: const Duration(seconds: 90),
    );
    final controller = await load();

    expect(controller.remainingNow().inSeconds, inInclusiveRange(89, 90));
  });

  test('an action the rules refuse never leaves the device', () async {
    repository.current = matchView(status: MatchStatus.inProgress);
    final controller = await load();

    expect(
      (await controller.send(MatchAction.finish))?.local,
      MatchRefusal.notOver,
    );
    await pumpEventQueue();
    expect(repository.sent, isEmpty);
  });

  test(
    'five fast points show at once and go out one at a time, in order',
    () async {
      repository.current = matchView(status: MatchStatus.inProgress);
      final controller = await load();
      // The server takes its time with each answer.
      repository.hold = Completer();

      for (var i = 0; i < 5; i++) {
        unawaited(controller.send(MatchAction.point, side: Side.red));
      }
      await pumpEventQueue();

      expect(shown()?.red.points, 5);
      expect(repository.sent, hasLength(1));
      expect(container.read(offlineSyncProvider).pendingCount, 5);

      repository.hold!.complete();
      await pumpEventQueue();

      expect(repository.knownSent, [1, 2, 3, 4, 5]);
      expect(shown()?.red.points, 5);
      expect(container.read(offlineSyncProvider).pendingCount, 0);
    },
  );
}
