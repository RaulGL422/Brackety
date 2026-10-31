import 'package:brackety/app.dart';
import 'package:brackety/features/events/data/my_event.dart';
import 'package:brackety/features/events/state/events_providers.dart';
import 'package:brackety/features/grouping/data/grouping_models.dart';
import 'package:brackety/features/grouping/data/grouping_repository.dart';
import 'package:brackety/features/grouping/state/group_draft.dart';
import 'package:brackety/core/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

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
            myEventsProvider.overrideWith(
              (ref) async => [
                MyEvent(
                  id: 'e1',
                  name: 'Fase 1',
                  date: DateTime(2027, 3, 10),
                  roles: const {EventRole.grouper},
                  maxGroupsPerMat: 1,
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

      expect(find.text('Zoe Prueba'), findsOneWidget);
      expect(find.textContaining('Group 3 · Mat 2'), findsOneWidget);

      await tester.tap(find.text('Height'));
      await tester.pumpAndSettle();
      final names = tester
          .widgetList<Text>(find.textContaining(' Prueba'))
          .map((t) => t.data)
          .toList();
      expect(names.first, 'Zoe Prueba');

      for (final name in ['Ana', 'Bea', 'Carla', 'Diego']) {
        await tester.tap(find.text('$name Prueba'));
        await tester.pump();
      }
      await tester.tap(find.text('Create group'));
      await tester.pumpAndSettle();

      expect(repository.created.single.single.members, [
        'p0',
        'p1',
        'p2',
        'p3',
      ]);
      expect(find.text('Group 1 → Mat 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

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

    final DraftGroup group = repository.created.single.single;
    expect(group.members, ['p0', 'p1', 'p2']);
    expect(group.ghost, 'grouped');
  });
}

class FakeGroupingRepository implements GroupingRepository {
  FakeGroupingRepository(this.list);

  final List<CategoryParticipant> list;
  final created = <List<DraftGroup>>[];

  @override
  Future<List<CategoryParticipant>> participants(
    String eventId,
    String categoryId,
  ) async => list;

  @override
  Future<List<CategorySummary>> categories(String eventId) async => [];

  @override
  Future<CreatedGroups> create(
    String eventId,
    String categoryId,
    List<DraftGroup> groups,
  ) async {
    created.add(groups);
    return CreatedGroups(
      matNumber: 2,
      groupNumbers: [for (var i = 0; i < groups.length; i++) i + 1],
    );
  }
}
