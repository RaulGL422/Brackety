import 'package:brackety/features/mat/data/mat_board.dart';
import 'package:brackety/features/offline/state/offline_sync.dart';
import 'package:brackety/features/scoreboard/data/match_view.dart';
import 'package:brackety/features/scoreboard/data/scoreboard_repository.dart';
import 'package:brackety/features/scoreboard/state/bell.dart';
import 'package:brackety/features/scoreboard/state/match_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/match_fakes.dart';

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
        // The web: actions straight to the server (the queue has its own tests).
        offlineEnabledProvider.overrideWithValue(false),
        bellProvider.overrideWithValue(bell),
        scoreboardRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
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

  test(
    'the bell rings when the clock starts and when the match ends on points',
    () async {
      final controller = await load();

      repository.next = matchView(
        status: MatchStatus.inProgress,
        running: true,
      );
      await controller.send(MatchAction.start);
      expect(bell.rings, 1);

      repository.next = matchView(
        status: MatchStatus.inProgress,
        redPoints: 1,
        running: true,
      );
      await controller.send(MatchAction.point, side: Side.red);
      expect(bell.rings, 1);

      repository.next = matchView(
        status: MatchStatus.inProgress,
        redPoints: 15,
        endReason: EndReason.points,
      );
      await controller.send(MatchAction.point, side: Side.red);
      expect(bell.rings, 2);
    },
  );

  test(
    'time running out here rings once, not again when the server confirms it',
    () async {
      repository.current = matchView(
        status: MatchStatus.inProgress,
        running: true,
      );
      final controller = await load();

      controller.timeUp();
      controller.timeUp();
      repository.next = matchView(
        status: MatchStatus.inProgress,
        remaining: Duration.zero,
        endReason: EndReason.time,
      );
      await controller.send(MatchAction.stop);

      expect(bell.rings, 1);
    },
  );

  test('after an undo reopens the match, its next end rings again', () async {
    repository.current = matchView(
      status: MatchStatus.inProgress,
      redPoints: 15,
      endReason: EndReason.points,
    );
    final controller = await load();

    repository.next = matchView(status: MatchStatus.inProgress, redPoints: 14);
    await controller.send(MatchAction.undo);
    repository.next = matchView(
      status: MatchStatus.inProgress,
      redPoints: 15,
      endReason: EndReason.points,
    );
    await controller.send(MatchAction.point, side: Side.red);

    expect(bell.rings, 1);
  });

  test('the clock counts down locally only while running', () async {
    repository.current = matchView(
      status: MatchStatus.inProgress,
      remaining: const Duration(seconds: 90),
    );
    final controller = await load();

    expect(controller.remainingNow(), const Duration(seconds: 90));
  });

  test('a refused action returns the server reason', () async {
    final controller = await load();
    repository.refusal = 'The match is not over yet.';

    expect(
      (await controller.send(MatchAction.finish))?.detail,
      'The match is not over yet.',
    );
  });

  test(
    'two quick actions go one at a time, each with what the last one left',
    () async {
      repository.current = matchView(status: MatchStatus.inProgress);
      final controller = await load();
      repository.next = matchView(
        status: MatchStatus.inProgress,
        canUndo: true,
      );

      final first = controller.send(MatchAction.point, side: Side.red);
      final second = controller.send(MatchAction.point, side: Side.red);
      await (first, second).wait;

      expect(repository.knownSent, [1, 2]);
    },
  );

  test('another device wrote first: refused as stale and reloaded', () async {
    final controller = await load();
    repository
      ..checkKnownEvents = true
      // The other device started the match meanwhile.
      ..current = matchView(status: MatchStatus.inProgress);

    final refusal = await controller.send(MatchAction.start);
    await Future<void>.delayed(Duration.zero);

    expect(refusal?.stale, isTrue);
    expect(
      container.read(matchControllerProvider('m1')).value?.status,
      MatchStatus.inProgress,
    );
  });
}
