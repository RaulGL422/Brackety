import 'package:brackety/features/mat/data/mat_board.dart';
import 'package:brackety/features/mat/state/mat_providers.dart';
import 'package:brackety/features/mat/ui/mat_board_screen.dart';
import 'package:brackety/l10n/gen/app_localizations.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
              matBoardProvider.overrideWith((ref, matId) async => board),
            ],
            child: MaterialApp(
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
        expect(find.text('Group 3 · ages 7-8'), findsOneWidget);
        expect(find.text('Recommended next'), findsOneWidget);
        expect(find.text('Ana  vs  Carla'), findsOneWidget);
        expect(
          find.text('A fighter is in a match on another mat'),
          findsOneWidget,
        );
        expect(find.text('4 - 15'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('the club can open a match that waits for a fighter', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [matBoardProvider.overrideWith((ref, matId) async => board)],
        child: MaterialApp(
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
      find.ancestor(
        of: find.text('Carla  vs  Diego (Ghost)'),
        matching: find.byType(ListTile),
      ),
    );
    expect(waiting.enabled, isTrue);
  });
}
