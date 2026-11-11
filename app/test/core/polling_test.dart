import 'dart:async';

import 'package:brackety/core/live/live_connection.dart';
import 'package:brackety/core/polling.dart';
import 'package:brackety/features/auth/state/session_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/live_fakes.dart';

// testWidgets for its fake clock: timers only move with pump.
void main() {
  const period = Duration(seconds: 2);

  testWidgets('the next poll waits for the last one to end', (tester) async {
    final answers = <Completer<void>>[];
    final poller = Poller(period, () {
      answers.add(Completer());
      return answers.last.future;
    });

    poller.schedule();
    await tester.pump(period);
    expect(answers, hasLength(1));

    // A slow server (up to the 10 s timeout): no second request meanwhile.
    await tester.pump(const Duration(seconds: 9));
    expect(answers, hasLength(1));

    answers.single.complete();
    await tester.pump();
    await tester.pump(period - const Duration(milliseconds: 1));
    expect(answers, hasLength(1));
    await tester.pump(const Duration(milliseconds: 1));
    expect(answers, hasLength(2));
    answers.last.complete();
    poller.dispose();
  });

  testWidgets('paused it does not poll; resumed it polls at once', (
    tester,
  ) async {
    var polls = 0;
    final poller = Poller(period, () async => polls++);

    poller.schedule();
    poller.pause();
    await tester.pump(const Duration(seconds: 30));
    expect(polls, 0);

    poller.resume();
    await tester.pump();
    expect(polls, 1);
    await tester.pump(period);
    expect(polls, 2);
    poller.dispose();
  });

  testWidgets('the first load counts as a poll', (tester) async {
    var polls = 0;
    final poller = Poller(period, () async => polls++);
    final first = Completer<int>();

    final loaded = poller.track(() => first.future);
    poller.resume();
    await tester.pump(const Duration(seconds: 5));
    expect(polls, 0);

    first.complete(1);
    expect(await loaded, 1);
    await tester.pump(period);
    expect(polls, 1);
    poller.dispose();
  });

  group('live reload', () {
    late FakeLiveServer server;
    late ProviderContainer container;
    var loads = 0;
    final provider = FutureProvider.autoDispose<int>(
      (ref) => liveReload(ref, {'event:e1'}, () async => ++loads),
    );

    setUp(() {
      loads = 0;
      server = FakeLiveServer();
      container = ProviderContainer(
        overrides: [
          ...sessionOverrides(FakeAuthApi(signedIn: true)),
          liveSocketConnectProvider.overrideWithValue(server.connect),
        ],
      );
      container.read(sessionProvider);
    });

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    testWidgets('a change on the server reloads at once; a burst, once', (
      tester,
    ) async {
      container.listen(provider, (_, _) {});
      await settle(tester);
      // The first load and one more when the socket confirmed it follows the event.
      expect(loads, 2);
      expect(server.open.single.watching, {'event:e1'});

      server.push({'event:e1'});
      await settle(tester);
      expect(loads, 3);

      for (var i = 0; i < 10; i++) {
        server.push({'event:e1'});
      }
      await settle(tester);
      expect(loads, 4);

      server.push({'event:other'});
      await settle(tester);
      expect(loads, 4);
      container.dispose();
    });

    testWidgets(
      'with the socket down it polls slowly, and reloads once when it is back',
      (tester) async {
        container.listen(provider, (_, _) {});
        await settle(tester);
        expect(loads, 2);

        server.down = true;
        server.dropAll();
        await settle(tester);
        expect(loads, 2);
        await tester.pump(liveFallback);
        await settle(tester);
        expect(loads, 3);

        server.down = false;
        await tester.pump(LiveConnection.maxRetry);
        await settle(tester);
        expect(server.open, hasLength(1));
        expect(loads, 4);
        container.dispose();
      },
    );

    testWidgets('an expired token gets a new one before reconnecting', (
      tester,
    ) async {
      container.listen(provider, (_, _) {});
      await settle(tester);
      final first = server.tokens.single;

      server.refusedTokens.add(first);
      server.dropAll(4001);
      await tester.pump(LiveConnection.maxRetry);
      await settle(tester);

      expect(server.tokens, hasLength(2));
      expect(server.tokens.last, isNot(first));
      expect(server.open, hasLength(1));
      container.dispose();
    });

    testWidgets('in the background it stops; back in front it reloads', (
      tester,
    ) async {
      container.listen(provider, (_, _) {});
      await settle(tester);
      expect(loads, 2);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      server.push({'event:e1'});
      await tester.pump(const Duration(minutes: 2));
      expect(loads, 2);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      expect(loads, 3);
      container.dispose();
    });
  });
}
