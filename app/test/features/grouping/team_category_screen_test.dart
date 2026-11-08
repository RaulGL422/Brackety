import 'package:brackety/app.dart';
import 'package:brackety/core/router.dart';
import 'package:brackety/features/events/state/events_providers.dart';
import 'package:brackety/features/grouping/data/grouping_models.dart';
import 'package:brackety/features/grouping/data/grouping_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/grouping_fakes.dart';

void main() {
  const sizes = {
    'phone': Size(360, 800),
    'tablet': Size(800, 1280),
    'desktop': Size(1440, 900),
  };

  // p0-p8 make teams 1-3; Fede, Gema, Hugo, Iris and Juan have no team yet.
  final names = [
    'Ana', 'Bea', 'Carla', 'Diego', 'Eva', 'Fran', 'Gil', 'Hana', 'Ivo', //
    'Fede', 'Gema', 'Hugo', 'Iris', 'Juan',
  ];
  final participants = [
    for (final (i, name) in names.indexed)
      CategoryParticipant(
        id: 'p$i',
        firstName: name,
        lastName: 'Prueba',
        age: 15,
        heightCm: 160 + i,
        teamNumber: i < 9 ? i ~/ 3 + 1 : null,
      ),
  ];
  final teams = [
    for (var t = 0; t < 3; t++)
      Team(
        id: 't${t + 1}',
        number: t + 1,
        members: [
          for (var i = 3 * t; i < 3 * t + 3; i++)
            TeamMember(participantId: 'p$i', fullName: '${names[i]} Prueba'),
        ],
      ),
  ];

  Future<FakeGroupingRepository> open(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = FakeGroupingRepository(participants, teamList: teams);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...sessionOverrides(FakeAuthApi(signedIn: true)),
          groupingRepositoryProvider.overrideWithValue(repository),
          fakeMatsOverride,
          myEventsProvider.overrideWith((ref) async => []),
        ],
        child: const BracketyApp(),
      ),
    );
    await tester.pumpAndSettle();
    ProviderScope.containerOf(tester.element(find.byType(BracketyApp)))
        .read(routerProvider)
        .push('/events/e1/categories/c1/teams?name=15-16&size=3');
    await tester.pumpAndSettle();
    return repository;
  }

  for (final MapEntry(key: device, value: size) in sizes.entries) {
    testWidgets('a helper makes a team from free participants on $device', (
      tester,
    ) async {
      final repository = await open(tester, size);

      expect(find.text('Individual group'), findsOneWidget);
      expect(find.text('New team · 0/3'), findsOneWidget);
      // Ana is in team 1: she cannot be picked again.
      await tester.tap(find.text('Ana Prueba'));
      await tester.pump();
      expect(find.text('New team · 0/3'), findsOneWidget);

      for (final name in ['Fede', 'Gema', 'Hugo', 'Iris']) {
        await tester.scrollUntilVisible(
          find.text('$name Prueba'),
          100,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(find.text('$name Prueba'));
        await tester.pump();
      }
      expect(find.text('New team · 3/3'), findsOneWidget);
      await tester.tap(find.text('Create team'));
      await tester.pumpAndSettle();

      expect(repository.createdTeams.single, ['p9', 'p10', 'p11']);
      expect(find.text('Team 4 created'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('three teams and a ghost team make a group on $device', (
      tester,
    ) async {
      final repository = await open(tester, size);
      await tester.tap(find.text('Teams'));
      await tester.pumpAndSettle();

      for (final team in ['Team 1', 'Team 2', 'Team 3']) {
        await tester.tap(find.text(team));
        await tester.pump();
      }
      await tester.tap(find.text('Ghost team'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pick participants · 0/3'));
      await tester.pumpAndSettle();

      // The group's own fighters are not offered for its ghost team.
      expect(find.widgetWithText(CheckboxListTile, 'Ana Prueba'), findsNothing);
      for (final name in ['Fede', 'Gema', 'Hugo']) {
        await tester.tap(find.widgetWithText(CheckboxListTile, '$name Prueba'));
        await tester.pump();
      }
      await tester.tap(
        find.widgetWithText(FilledButton, 'Pick participants · 3/3'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create group'));
      await tester.pumpAndSettle();

      final group = repository.created.single;
      expect(group.members, ['t1', 't2', 't3']);
      expect(group.ghostTeam, ['p9', 'p10', 'p11']);
      expect(find.text('Group 1'), findsWidgets);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Mat 2'),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the individual group leads back to the team group', (
    tester,
  ) async {
    await open(tester, sizes['phone']!);

    await tester.tap(find.text('Individual group'));
    await tester.pumpAndSettle();
    expect(find.text('New team · 0/3'), findsNothing);

    await tester.tap(find.text('Team group'));
    await tester.pumpAndSettle();
    expect(find.text('New team · 0/3'), findsOneWidget);
  });

  testWidgets('a team without a group can be undone', (tester) async {
    final repository = await open(tester, sizes['tablet']!);
    await tester.tap(find.text('Teams'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Undo team').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Undo team'));
    await tester.pumpAndSettle();

    expect(repository.deletedTeams, ['t1']);
  });
}
