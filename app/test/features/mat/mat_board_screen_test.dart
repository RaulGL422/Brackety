import 'package:brackety/features/mat/data/mat_board.dart';
import 'package:brackety/features/mat/state/mat_providers.dart';
import 'package:brackety/features/mat/ui/mat_board_screen.dart';
import 'package:brackety/features/offline/state/offline_sync.dart';
import 'package:brackety/l10n/gen/app_localizations.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/board_finders.dart';

void main() {
  const sizes = {
    'phone': Size(360, 800),
    'tablet': Size(800, 1280),
    'desktop': Size(1440, 900),
  };

  Fighter fighter(String name, {bool ghost = false}) =>
      Fighter(participantId: name, name: name, ghost: ghost);

  BoardMatch match(
    String id,
    Fighter red,
    Fighter blue,
    MatchStatus status, {
    bool available = true,
  }) => BoardMatch(
    id: id,
    groupId: 'g1',
    groupNumber: 3,
    red: red,
    blue: blue,
    status: status,
    redScore: status == MatchStatus.finished ? 4 : 0,
    blueScore: status == MatchStatus.finished ? 15 : 0,
    available: available,
  );

  final ana = fighter('Ana');
  final bea = fighter('Bea');
  final carla = fighter('Carla');
  final ghost = fighter('Diego', ghost: true);
  final board = MatBoard(
    matNumber: 2,
    groups: [
      BoardGroup(
        id: 'g1',
        number: 3,
        categoryName: '7-8',
        members: [ana, bea, carla, ghost],
      ),
    ],
    matches: [
      match('m1', ana, bea, MatchStatus.finished),
      match('m2', carla, ghost, MatchStatus.pending, available: false),
      match('m3', ana, carla, MatchStatus.pending),
    ],
    recommendedMatchId: 'm3',
  );

  for (final MapEntry(key: device, value: size) in sizes.entries) {
    testWidgets(
      'the mat shows its group, the recommended match and why one waits on $device',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              offlineEnabledProvider.overrideWithValue(false),
              matBoardProvider.overrideWith((ref, matId) async => board),
            ],
            child: MaterialApp(
              builder: (_, child) => ToastHost(child: child!),
              theme: lightTheme(),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...coreLocalizationsDelegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: const MatBoardScreen(matId: 'mat2'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mat 2'), findsOneWidget);
        expect(
          find.text('Group 3, ages 7-8', skipOffstage: false),
          findsNWidgets(2),
        );
        expect(find.text('Recommended match'), findsOneWidget);
        expect(find.text('2 to play'), findsOneWidget);
        expect(matchTile('Ana', 'Carla'), findsOneWidget);
        expect(find.text('A fighter is in a match right now'), findsOneWidget);
        expect(find.text('4 - 15'), findsOneWidget);
        // Nothing in progress: one big action and why this one.
        expect(
          find.widgetWithText(FilledButton, 'Start this match'),
          findsOneWidget,
        );
        expect(find.textContaining('rested the longest'), findsOneWidget);
        // The one that cannot start has its own section, apart from the others.
        expect(find.text('Waiting'), findsOneWidget);
        expect(find.text('Other available matches'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'in progress and recommended stand apart and a waiting match is locked on $device',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final live = MatBoard(
          matNumber: 2,
          groups: board.groups,
          matches: [
            match('m0', bea, carla, MatchStatus.inProgress),
            ...board.matches,
          ],
          recommendedMatchId: 'm3',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              offlineEnabledProvider.overrideWithValue(false),
              matBoardProvider.overrideWith((ref, matId) async => live),
            ],
            child: MaterialApp(
              builder: (_, child) => ToastHost(child: child!),
              theme: lightTheme(),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...coreLocalizationsDelegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: const MatBoardScreen(matId: 'mat2'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final scheme = Theme.of(tester.element(find.byType(ListView)))
            .colorScheme;
        Finder card(Finder tile) =>
            find.ancestor(of: tile, matching: find.byType(Card)).first;
        ListTile tile(Finder tile) => tester.widget<ListTile>(tile);

        final inProgress = card(matchTile('Bea', 'Carla'));
        expect(
          find.descendant(of: inProgress, matching: find.text('In progress')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: inProgress,
            matching: find.text('Back to the scoreboard'),
          ),
          findsOneWidget,
        );

        final recommended = card(matchTile('Ana', 'Carla'));
        expect(
          find.descendant(
            of: recommended,
            matching: find.text('When the match in progress ends.'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: recommended,
            matching: find.text('Recommended match'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: recommended,
            matching: find.text('Open the scoreboard'),
          ),
          findsOneWidget,
        );
        // Next stands out by a thick ink frame, not by a colour a competitor may wear.
        final frame =
            tester.widget<Card>(recommended).shape! as RoundedRectangleBorder;
        expect(frame.side.color, scheme.onSurface);
        expect(frame.side.width, 3);

        final waiting = matchTile('Carla', 'Diego · Ghost');
        await tester.scrollUntilVisible(waiting, 200);
        expect(tile(waiting).onTap, isNull);
        expect(tile(waiting).enabled, isTrue);
        expect(
          find.descendant(
            of: waiting,
            matching: find.byIcon(Icons.lock_outline),
          ),
          findsOneWidget,
        );
        // The group is its number in ink: a colour could be taken for a competitor's.
        final badge = tester.widget<Container>(
          find
              .ancestor(
                of: find.descendant(of: waiting, matching: find.text('3')),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(
          (badge.decoration! as BoxDecoration).color,
          scheme.inverseSurface,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('the title says the mat while the board fails to load', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          offlineEnabledProvider.overrideWithValue(false),
          matBoardProvider.overrideWith(
            (ref, matId) async => throw Exception('down'),
          ),
        ],
        child: MaterialApp(
          builder: (_, child) => ToastHost(child: child!),
          theme: lightTheme(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...coreLocalizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MatBoardScreen(matId: 'mat2', matNumber: 2),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Mat 2'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('the club can open a match that waits for a fighter', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineEnabledProvider.overrideWithValue(false),
          matBoardProvider.overrideWith((ref, matId) async => board),
        ],
        child: MaterialApp(
          builder: (_, child) => ToastHost(child: child!),
          theme: lightTheme(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...coreLocalizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MatBoardScreen(matId: 'mat2', readOnly: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final waiting = tester.widget<ListTile>(
      matchTile('Carla', 'Diego · Ghost'),
    );
    expect(waiting.onTap, isNotNull);
  });

  test('a team fighter has no participant id and keeps its members', () {
    final f = Fighter.fromJson({
      'participantId': null,
      'name': 'Ana P, Bea P, Carla P',
      'ghost': false,
      'teamId': 't1',
      'teamNumber': 1,
      'members': ['Ana P', 'Bea P', 'Carla P'],
    });

    expect(f.participantId, isNull);
    expect(f.teamNumber, 1);
    expect(f.members, hasLength(3));
  });

  for (final MapEntry(key: device, value: size) in sizes.entries) {
    testWidgets('teams are called by number on $device', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Fighter team(int n, {bool ghost = false}) => Fighter(
        participantId: null,
        name: 'x',
        ghost: ghost,
        teamNumber: n,
        members: ['A$n', 'B$n', 'C$n'],
      );
      final teams = [team(1), team(2), team(3), team(4, ghost: true)];
      final teamBoard = MatBoard(
        matNumber: 1,
        groups: [
          BoardGroup(
            id: 'g1',
            number: 1,
            categoryName: '15-16',
            members: teams,
          ),
        ],
        matches: [match('m1', teams[0], teams[1], MatchStatus.pending)],
        recommendedMatchId: 'm1',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            offlineEnabledProvider.overrideWithValue(false),
            matBoardProvider.overrideWith((ref, matId) async => teamBoard),
          ],
          child: MaterialApp(
            builder: (_, child) => ToastHost(child: child!),
            theme: lightTheme(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              ...coreLocalizationsDelegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const MatBoardScreen(matId: 'mat1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(matchTile('Team 1', 'Team 2'), findsOneWidget);
      expect(find.text('Team 4 · Ghost'), findsOneWidget);
      expect(find.text('A1, B1, C1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
