import 'package:brackety/app.dart';
import 'package:brackety/features/events/data/my_event.dart';
import 'package:brackety/features/events/state/events_providers.dart';
import 'package:brackety/features/grouping/data/grouping_models.dart';
import 'package:brackety/features/grouping/data/grouping_repository.dart';
import 'package:brackety/features/grouping/state/group_draft.dart';
import 'package:brackety/features/grouping/state/grouping_providers.dart';
import 'package:brackety/core/router.dart';
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

  final participants = [
    for (final (i, name) in ['Ana', 'Bea', 'Carla', 'Diego', 'Eva'].indexed)
      CategoryParticipant(
        id: 'p$i',
        firstName: name,
        lastName: 'Prueba',
        age: 7,
        heightCm: 130 - i,
      ),
    const CategoryParticipant(
      id: 'grouped',
      firstName: 'Zoe',
      lastName: 'Prueba',
      age: 7,
      heightCm: 120,
      groupNumber: 3,
      matNumber: 2,
    ),
  ];

  for (final MapEntry(key: device, value: size) in sizes.entries) {
    testWidgets('a helper makes a group and sees its mat on $device', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repository = FakeGroupingRepository(participants);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...sessionOverrides(FakeAuthApi(signedIn: true)),
            groupingRepositoryProvider.overrideWithValue(repository),
            fakeMatsOverride,
            myEventsProvider.overrideWith(
              (ref) async => [
                MyEvent(
                  id: 'e1',
                  name: 'Fase 1',
                  date: DateTime(2027, 3, 10),
                  roles: const {EventRole.grouper},
                ),
              ],
            ),
          ],
          child: const BracketyApp(),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(BracketyApp)),
      );
      container
          .read(routerProvider)
          .push('/events/e1/categories/c1', extra: '7-8');
      await tester.pumpAndSettle();

      // On a phone the list starts below the group's slots: Zoe is further down.
      final list = find.byType(Scrollable).last;
      Future<void> toTop() async {
        await tester.drag(list, const Offset(0, 2000));
        await tester.pumpAndSettle();
      }

      await tester.scrollUntilVisible(
        find.text('Zoe Prueba'),
        200,
        scrollable: list,
      );
      expect(find.text('Zoe Prueba'), findsOneWidget);
      expect(find.textContaining('Group 3 · Mat 2'), findsOneWidget);

      await tester.tap(find.text('Height'));
      await tester.pumpAndSettle();
      await toTop();
      final names = tester
          .widgetList<Text>(find.textContaining(' Prueba'))
          .map((t) => t.data)
          .toList();
      expect(names.first, 'Zoe Prueba');

      for (final name in ['Ana', 'Bea', 'Carla', 'Diego']) {
        // On a phone the group's slots leave room for a few rows: scroll to each one.
        await toTop();
        await tester.scrollUntilVisible(
          find.text('$name Prueba'),
          100,
          scrollable: list,
        );
        await tester.ensureVisible(find.text('$name Prueba'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('$name Prueba'));
        await tester.pump();
      }
      await tester.tap(find.text('Create group'));
      await tester.pumpAndSettle();

      expect(repository.created.single.members, ['p0', 'p1', 'p2', 'p3']);
      expect(find.text('Group 1'), findsWidgets);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Mat 2'),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      expect(repository.createdOnMat.single, isNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'someone another helper groups meanwhile leaves the draft with a notice',
    (tester) async {
      tester.view.physicalSize = sizes['tablet']!;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repository = FakeGroupingRepository([...participants]);
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
      final container = ProviderScope.containerOf(
        tester.element(find.byType(BracketyApp)),
      );
      container
          .read(routerProvider)
          .push('/events/e1/categories/c1', extra: '7-8');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ana Prueba'));
      await tester.tap(find.text('Bea Prueba'));
      await tester.pump();

      // Another helper puts Ana in group 5; the event's live signal reloads the list.
      repository.list[0] = const CategoryParticipant(
        id: 'p0',
        firstName: 'Ana',
        lastName: 'Prueba',
        age: 7,
        heightCm: 130,
        groupNumber: 5,
        matNumber: 1,
      );
      container.invalidate(
        categoryParticipantsProvider((eventId: 'e1', categoryId: 'c1')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Ana Prueba is already in another group: taken out of the new group.',
        ),
        findsOneWidget,
      );
      expect(find.text('Ana P.'), findsNothing);
      expect(find.text('Bea P.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('with the ghost box, the fourth pick is a ghost', (tester) async {
    tester.view.physicalSize = sizes['tablet']!;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = FakeGroupingRepository(participants);
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
        .push('/events/e1/categories/c1');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ghost competitor'));
    for (final name in ['Ana', 'Bea', 'Carla', 'Zoe']) {
      await tester.tap(find.text('$name Prueba'));
      await tester.pump();
    }
    await tester.tap(find.text('Create group'));
    await tester.pumpAndSettle();

    final DraftGroup group = repository.created.single;
    expect(group.members, ['p0', 'p1', 'p2']);
    expect(group.ghost, 'grouped');
  });

  testWidgets('the slots fill as the helper picks and a tap empties one', (
    tester,
  ) async {
    tester.view.physicalSize = sizes['tablet']!;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...sessionOverrides(FakeAuthApi(signedIn: true)),
          groupingRepositoryProvider.overrideWithValue(
            FakeGroupingRepository(participants),
          ),
          fakeMatsOverride,
          myEventsProvider.overrideWith((ref) async => []),
        ],
        child: const BracketyApp(),
      ),
    );
    await tester.pumpAndSettle();
    ProviderScope.containerOf(tester.element(find.byType(BracketyApp)))
        .read(routerProvider)
        .push('/events/e1/categories/c1');
    await tester.pumpAndSettle();

    expect(find.textContaining('4 to go', findRichText: true), findsOneWidget);
    expect(find.text('Slot 1'), findsOneWidget);
    for (final name in ['Ana', 'Bea']) {
      await tester.tap(find.text('$name Prueba'));
      await tester.pump();
    }
    expect(find.textContaining('2 to go', findRichText: true), findsOneWidget);
    expect(find.text('Ana P.'), findsOneWidget);
    expect(find.text('Slot 3'), findsOneWidget);

    await tester.tap(find.text('Ana P.'));
    await tester.pump();
    expect(find.text('Ana P.'), findsNothing);
    expect(find.textContaining('3 to go', findRichText: true), findsOneWidget);

    for (final name in ['Ana', 'Carla', 'Diego']) {
      await tester.tap(find.text('$name Prueba'));
      await tester.pump();
    }
    expect(find.textContaining('Complete', findRichText: true), findsOneWidget);
  });

  for (final MapEntry(key: device, value: size) in sizes.entries) {
    testWidgets('the helper can pick a mat with a referee on $device', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repository = FakeGroupingRepository(participants);
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
          .push('/events/e1/categories/c1');
      await tester.pumpAndSettle();

      expect(find.text('Automatic'), findsWidgets);
      expect(
        find.text(
          'It is assigned automatically to the mat that will be free first.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byType(DropdownButtonFormField<String?>));
      await tester.pumpAndSettle();
      expect(find.text('No referee'), findsOneWidget);
      // Mat 2 has no referee: tapping it leaves the menu open and nothing picked.
      await tester.tap(find.text('Mat 2').last, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('No referee'), findsOneWidget);
      await tester.tap(find.text('Mat 1').last);
      await tester.pumpAndSettle();
      expect(find.text('It goes to Mat 1, picked by hand.'), findsOneWidget);

      for (final name in ['Ana', 'Bea', 'Carla', 'Diego']) {
        await tester.tap(find.text('$name Prueba'));
        await tester.pump();
      }
      await tester.tap(find.text('Create group'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(repository.createdOnMat.single, 'm1');
      // Back to automatic for the next group.
      expect(
        find.text(
          'It is assigned automatically to the mat that will be free first.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  Future<FakeGroupingRepository> openBuilder(
    WidgetTester tester,
    List<CategoryParticipant> list,
  ) async {
    tester.view.physicalSize = sizes['tablet']!;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = FakeGroupingRepository(list);
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
        .push('/events/e1/categories/c1');
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('a group just made can be undone from its dialog', (
    tester,
  ) async {
    final repository = await openBuilder(tester, participants);
    for (final name in ['Ana', 'Bea', 'Carla', 'Diego']) {
      await tester.tap(find.text('$name Prueba'));
      await tester.pump();
    }
    await tester.tap(find.text('Create group'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Undo group'));
    await tester.pumpAndSettle();
    expect(find.textContaining('go back to the list'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Undo group'));
    await tester.pumpAndSettle();

    expect(repository.undoneGroups, ['g1']);
    expect(find.text('Group 1 undone'), findsOneWidget);
  });

  testWidgets('a group can be undone until one of its matches starts', (
    tester,
  ) async {
    const open = CategoryParticipant(
      id: 'open',
      firstName: 'Iker',
      lastName: 'Prueba',
      age: 7,
      groupNumber: 4,
      matNumber: 1,
      groupId: 'g4',
    );
    const started = CategoryParticipant(
      id: 'started',
      firstName: 'Lola',
      lastName: 'Prueba',
      age: 7,
      groupNumber: 5,
      matNumber: 1,
      groupId: 'g5',
      groupStarted: true,
    );
    final repository = await openBuilder(tester, [open, started]);

    expect(find.byTooltip('Undo Group 5'), findsNothing);
    await tester.tap(find.byTooltip('Undo Group 4'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Undo group'));
    await tester.pumpAndSettle();
    expect(repository.undoneGroups, ['g4']);
  });

  testWidgets('a group whose match started meanwhile says who can undo it', (
    tester,
  ) async {
    const open = CategoryParticipant(
      id: 'open',
      firstName: 'Iker',
      lastName: 'Prueba',
      age: 7,
      groupNumber: 4,
      matNumber: 1,
      groupId: 'g4',
    );
    final repository = await openBuilder(tester, [open])
      ..undoRefusal = 409;

    await tester.tap(find.byTooltip('Undo Group 4'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Undo group'));
    await tester.pumpAndSettle();

    expect(repository.undoneGroups, isEmpty);
    expect(find.textContaining('only the administrator'), findsOneWidget);
  });
}
