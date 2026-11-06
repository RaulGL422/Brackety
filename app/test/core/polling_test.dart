import 'dart:async';

import 'package:brackety/core/polling.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('a polled provider stops in the background and reloads back', (
    tester,
  ) async {
    var loads = 0;
    final provider = FutureProvider.autoDispose<int>(
      (ref) => reloadEvery(ref, period, () async => ++loads),
    );
    final container = ProviderContainer();
    container.listen(provider, (_, _) {});

    await tester.pump();
    expect(loads, 1);
    await tester.pump(period);
    await tester.pump();
    expect(loads, 2);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 30));
    expect(loads, 2);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    // Riverpod rebuilds on a zero timer of its own.
    await tester.pump(const Duration(milliseconds: 1));
    expect(loads, 3);
    await tester.pump(period);
    await tester.pump();
    expect(loads, 4);
    // Timers must be gone before the test ends.
    container.dispose();
  });
}
