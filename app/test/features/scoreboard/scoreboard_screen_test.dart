import 'package:brackety/core/keep_screen_on.dart';
import 'package:brackety/features/mat/data/mat_board.dart';
import 'package:brackety/features/offline/state/offline_sync.dart';
import 'package:brackety/features/scoreboard/data/match_view.dart';
import 'package:brackety/features/scoreboard/data/scoreboard_repository.dart';
import 'package:brackety/features/scoreboard/state/bell.dart';
import 'package:brackety/features/scoreboard/ui/scoreboard_screen.dart';
import 'package:brackety/l10n/gen/app_localizations.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/match_fakes.dart';

void main() {
  const sizes = {
    'phone': Size(360, 800),
    'tablet': Size(800, 1280),
    'desktop': Size(1440, 900),
  };

  // The clock repaints every 200 ms, so these tests pump time instead of waiting to settle.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<(FakeScoreboardRepository, FakeBell)> open(
    WidgetTester tester,
    MatchView view,
  ) async {
    final repository = FakeScoreboardRepository(view);
    final bell = FakeBell();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineEnabledProvider.overrideWithValue(false),
          scoreboardRepositoryProvider.overrideWithValue(repository),
          bellProvider.overrideWithValue(bell),
        ],
        child: MaterialApp(
          theme: lightTheme(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...coreLocalizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ScoreboardScreen(matchId: 'm1'),
        ),
      ),
    );
    await settle(tester);
    return (repository, bell);
  }

  for (final MapEntry(key: device, value: size) in sizes.entries) {
    testWidgets('the referee starts the clock and scores on $device', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final (repository, bell) = await open(tester, matchView());

      expect(find.text('2:00'), findsOneWidget);
      expect(find.text('Ana Prueba'), findsOneWidget);

      repository.next = matchView(
        status: MatchStatus.inProgress,
        running: true,
      );
      await tester.tap(find.text('Start'));
      await settle(tester);
      expect(bell.rings, 1);
      expect(find.text('Stop'), findsOneWidget);

      repository.next = matchView(
        status: MatchStatus.inProgress,
        running: true,
        redPoints: 1,
        canUndo: true,
      );
      await tester.tap(find.text('+1').first);
      await settle(tester);

      expect(repository.sent.last, (MatchAction.point, Side.red, null));
      expect(find.text('1'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final MapEntry(key: device, value: size) in sizes.entries) {
    testWidgets('a team match shows the team numbers and members on $device', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await open(
        tester,
        matchView(
          red: teamCorner(1, ['Ana P', 'Bea P', 'Carla P']),
          blue: teamCorner(4, ['Diego P', 'Eva P', 'Fran P'], ghost: true),
        ),
      );

      expect(find.text('Team 1'), findsOneWidget);
      expect(find.text('Ana P, Bea P, Carla P'), findsOneWidget);
      expect(find.text('Team 4 · Ghost'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('a warning needs a confirmed reason', (tester) async {
    tester.view.physicalSize = sizes['tablet']!;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (repository, _) = await open(
      tester,
      matchView(status: MatchStatus.inProgress),
    );

    await tester.tap(find.byType(PopupMenuButton<MatchAction>).first);
    await settle(tester);
    expect(find.text('Warning for hitting with one hand'), findsOneWidget);
    await tester.tap(find.text('Warning'));
    await settle(tester);

    final confirm = find.widgetWithText(FilledButton, 'Confirm');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'Ataque de pique');
    await settle(tester);
    await tester.tap(confirm);
    await settle(tester);

    expect(repository.sent.single, (
      MatchAction.warning,
      Side.red,
      'Ataque de pique',
    ));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('when the match is over only finishing is left', (tester) async {
    tester.view.physicalSize = sizes['tablet']!;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (repository, _) = await open(
      tester,
      matchView(
        status: MatchStatus.inProgress,
        redPoints: 15,
        endReason: EndReason.points,
        canUndo: true,
      ),
    );

    expect(find.text('Ended on points'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '+1').first)
          .onPressed,
      isNull,
    );

    repository.next = matchView(status: MatchStatus.finished, redPoints: 15);
    await tester.tap(find.text('Finish match'));
    await settle(tester);

    expect(repository.sent.single.$1, MatchAction.finish);
    expect(find.text('Match finished'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  final longNames = matchView(
    status: MatchStatus.inProgress,
    running: true,
    canUndo: true,
    red: corner(
      'María de los Ángeles Fernández-Villaverde',
      points: 7,
      oneHandRule: true,
    ),
    blue: corner('Juan Sebastián Rodríguez de la Fuente', points: 5),
  );

  const layouts = {...sizes, 'landscape phone': Size(800, 360)};

  Finder undoButton(String label) => find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((w) => w is OutlinedButton),
  );

  void setSize(WidgetTester tester, Size size, {double scale = 1}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  for (final MapEntry(key: device, value: size) in layouts.entries) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('long names fit on $device with text at ${scale * 100}%', (
        tester,
      ) async {
        setSize(tester, size, scale: scale);
        await open(tester, longNames);

        expect(tester.takeException(), isNull);
        final name = tester.widget<Text>(
          find.text('María de los Ángeles Fernández-Villaverde'),
        );
        expect(name.maxLines, 1);
        expect(
          find.byTooltip('María de los Ángeles Fernández-Villaverde'),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets('in landscape the clock sits between red and blue', (
    tester,
  ) async {
    setSize(tester, layouts['landscape phone']!);
    await open(tester, longNames);

    double x(Finder f) => tester.getCenter(f).dx;
    expect(x(find.text('Red')), lessThan(x(find.text('Stop'))));
    expect(x(find.text('Stop')), lessThan(x(find.text('Blue'))));
    expect(
      tester.getCenter(find.text('2:00')).dy,
      lessThan(tester.getCenter(find.text('Stop')).dy),
    );

    await tester.pumpWidget(const SizedBox());
  });

  for (final MapEntry(key: device, value: size) in sizes.entries) {
    testWidgets('nothing scores before the clock first starts on $device', (
      tester,
    ) async {
      setSize(tester, size);
      FilledButton point() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '+1').first,
      );
      PopupMenuButton<MatchAction> menu() =>
          tester.widget<PopupMenuButton<MatchAction>>(
            find.byType(PopupMenuButton<MatchAction>).first,
          );

      await open(tester, matchView());
      expect(point().onPressed, isNull);
      expect(menu().enabled, isFalse);

      // Started once and stopped again: scoring is allowed.
      await tester.pumpWidget(const SizedBox());
      await open(tester, matchView(status: MatchStatus.inProgress));
      expect(point().onPressed, isNotNull);
      expect(menu().enabled, isTrue);

      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final MapEntry(key: device, value: size) in sizes.entries) {
    testWidgets('undo says what it undoes and confirms it on $device', (
      tester,
    ) async {
      setSize(tester, size);
      final (repository, _) = await open(
        tester,
        matchView(status: MatchStatus.inProgress, redPoints: 1, canUndo: true),
      );

      final undo = undoButton('Undo: +1 Red');
      expect(undo, findsOneWidget);
      expect(tester.getSize(undo).height, greaterThanOrEqualTo(48));

      repository.next = matchView(status: MatchStatus.inProgress);
      await tester.tap(undo);
      await settle(tester);

      expect(repository.sent.single.$1, MatchAction.undo);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Undone: +1 Red'), findsOneWidget);
      expect(undoButton('Undo'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await settle(tester);
      expect(find.text('Undone: +1 Red'), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('a warning undo names the warning and the corner', (
    tester,
  ) async {
    setSize(tester, sizes['tablet']!);
    final view = matchView(status: MatchStatus.inProgress);
    await open(
      tester,
      MatchView(
        id: view.id,
        matId: view.matId,
        matNumber: view.matNumber,
        groupNumber: view.groupNumber,
        status: view.status,
        length: view.length,
        pointsLimit: view.pointsLimit,
        remaining: view.remaining,
        running: false,
        red: view.red,
        blue: view.blue,
        timeline: [
          ...view.timeline,
          TimelineEntry(
            action: MatchAction.warning,
            side: Side.blue,
            reason: 'x',
            at: DateTime(2027, 3, 10, 10, 1),
            clock: const Duration(seconds: 30),
            automatic: false,
            undone: false,
            gaveRivalPoint: false,
          ),
        ],
      ),
    );

    expect(find.text('Undo: Blue warning'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the last ten seconds show in the warning colour', (
    tester,
  ) async {
    setSize(tester, sizes['phone']!);
    await open(
      tester,
      matchView(
        status: MatchStatus.inProgress,
        remaining: const Duration(seconds: 8),
      ),
    );

    final clock = tester.widget<Text>(find.text('0:08'));
    final colors = BracketyColors.of(tester.element(find.text('0:08')));
    expect(clock.style?.color, colors.warning);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('stop is strong and unlike start', (tester) async {
    setSize(tester, sizes['phone']!);
    final (repository, _) = await open(
      tester,
      matchView(status: MatchStatus.inProgress),
    );
    Color? background(String label) => tester
        .widget<FilledButton>(
          find.ancestor(
            of: find.text(label),
            matching: find.byWidgetPredicate((w) => w is FilledButton),
          ),
        )
        .style
        ?.backgroundColor
        ?.resolve({});
    final scheme = Theme.of(tester.element(find.text('Resume'))).colorScheme;
    final start = background('Resume');

    repository.next = matchView(status: MatchStatus.inProgress, running: true);
    await tester.tap(find.text('Resume'));
    await settle(tester);

    expect(background('Stop'), scheme.inverseSurface);
    expect(background('Stop'), isNot(start));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('disqualification is in the error colour', (tester) async {
    setSize(tester, sizes['tablet']!);
    await open(tester, matchView(status: MatchStatus.inProgress));

    await tester.tap(find.byType(PopupMenuButton<MatchAction>).first);
    await settle(tester);
    final item = tester.widget<Text>(find.text('Disqualification'));
    final scheme = Theme.of(tester.element(find.text('Disqualification')))
        .colorScheme;
    expect(item.style?.color, scheme.error);

    await tester.pumpWidget(const SizedBox());
  });

  for (final MapEntry(key: device, value: size) in layouts.entries) {
    testWidgets('a finished match marks the winner on $device', (tester) async {
      setSize(tester, size, scale: 2);
      await open(
        tester,
        matchView(
          status: MatchStatus.finished,
          red: corner('Ana Prueba', points: 15),
        ),
      );

      expect(find.text('Red · Winner'), findsOneWidget);
      expect(find.text('Blue'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('the screen stays on while the scoreboard is open', (
    tester,
  ) async {
    final calls = <bool>[];
    final original = KeepScreenOn.toggle;
    KeepScreenOn.toggle = calls.add;
    addTearDown(() => KeepScreenOn.toggle = original);

    await open(tester, matchView());
    expect(calls, [true]);

    await tester.pumpWidget(const SizedBox());
    expect(calls, [true, false]);
  });
}
