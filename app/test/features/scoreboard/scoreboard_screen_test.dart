import 'package:brackety/features/mat/data/mat_board.dart';
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
}
