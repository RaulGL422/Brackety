import 'package:brackety_admin/features/events/data/events_api.dart';
import 'package:brackety_admin/features/events/state/events_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

class FakeEventsApi implements EventsApi {
  FakeEventsApi({this.total = 1});

  final int total;
  final pages = <int>[];
  final calls = <String>[];
  DioException? error;
  var groups = [group('g1', 1), group('g2', 2)];

  static AdminGroup group(String id, int number) => AdminGroup(
    id: id,
    number: number,
    category: '4-6',
    matNumber: number,
    matches: [
      AdminMatch(
        id: '$id-m1',
        order: 0,
        status: AdminMatchStatus.finished,
        red: const AdminSide(name: 'Leo Molina'),
        blue: const AdminSide(name: 'Noa Vázquez'),
        redScore: 15,
        blueScore: 3,
        inReview: false,
      ),
      AdminMatch(
        id: '$id-m2',
        order: 1,
        status: AdminMatchStatus.pending,
        red: const AdminSide(teamNumber: 2),
        blue: const AdminSide(teamNumber: 5),
        redScore: 0,
        blueScore: 0,
        inReview: false,
      ),
    ],
  );

  @override
  Future<AdminEventPage> list({required int page, int size = 20}) async {
    pages.add(page);
    return AdminEventPage(
      items: [
        AdminEventRow(
          id: 'e$page',
          name: 'Fase 1 página ${page + 1}',
          date: DateTime(2026, 11, 14),
          ownerEmail: 'club1',
          mats: 5,
          entries: 75,
          groups: groups.length,
          matchesFinished: 1,
          matches: 4,
        ),
      ],
      page: page,
      size: 20,
      total: total,
    );
  }

  @override
  Future<AdminEventDetail> detail(String eventId) async => AdminEventDetail(
    id: eventId,
    name: 'Fase 1',
    date: DateTime(2026, 11, 14),
    ownerEmail: 'club1',
    entries: 75,
    mats: const [
      AdminMat(id: 'm1', number: 1, referee: 'arbitro1'),
      AdminMat(id: 'm2', number: 2),
    ],
    groups: groups,
  );

  @override
  Future<void> resetMatch(String matchId, String reason) async {
    if (error case final e?) throw e;
    calls.add('reset $matchId: $reason');
  }

  @override
  Future<void> dissolveGroup(String groupId, String reason) async {
    calls.add('dissolve $groupId: $reason');
    groups = [
      for (final g in groups)
        if (g.id != groupId) g,
    ];
  }

  @override
  Future<Cleared> clearCompetition(String eventId, String reason) async {
    calls.add('clear $eventId: $reason');
    final cleared = (groups: groups.length, teams: 1);
    groups = [];
    return cleared;
  }
}

void main() {
  Future<FakeEventsApi> open(WidgetTester tester, {int total = 1}) async {
    final api = FakeEventsApi(total: total);
    await pumpAdmin(
      tester,
      location: '/events',
      overrides: [eventsApiProvider.overrideWithValue(api)],
    );
    return api;
  }

  Future<void> openDetail(WidgetTester tester) async {
    await tester.tap(find.text('Fase 1 página 1'));
    await tester.pumpAndSettle();
  }

  Future<void> giveReason(WidgetTester tester, String reason) async {
    await tester.enterText(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          )
          .first,
      reason,
    );
    await tester.pump();
  }

  for (final MapEntry(key: device, value: size) in screenSizes.entries) {
    testWidgets('events list and detail fit on $device', (tester) async {
      useSize(tester, size);
      await open(tester);

      expect(find.text('Fase 1 página 1'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await openDetail(tester);
      expect(find.text('Mat 1: arbitro1'), findsOneWidget);
      expect(find.text('Mat 2: no referee'), findsOneWidget);
      expect(find.text('Group 1, 4-6'), findsOneWidget);
      expect(find.text('Leo Molina'), findsWidgets);
      expect(find.text('Team 2'), findsWidgets);
      expect(find.text('15–3'), findsWidgets);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Back to the events'));
      await tester.pumpAndSettle();
      expect(find.text('Fase 1 página 1'), findsOneWidget);
    });
  }

  testWidgets(
    'a played match restarts with a reason; a pending one has no button',
    (tester) async {
      useSize(tester, screenSizes['desktop']!);
      final api = await open(tester);
      await openDetail(tester);

      // One "Restart" per group: only the finished matches.
      expect(find.text('Restart'), findsNWidgets(2));
      await tester.tap(find.text('Restart').first);
      await tester.pumpAndSettle();
      final confirm = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Restart'),
      );
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

      await giveReason(tester, 'Empezó sin el árbitro');
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(api.calls, ['reset g1-m1: Empezó sin el árbitro']);
      expect(find.text('Match restarted.'), findsOneWidget);
    },
  );

  testWidgets('cancelling asks nothing of the server', (tester) async {
    useSize(tester, screenSizes['desktop']!);
    final api = await open(tester);
    await openDetail(tester);

    await tester.tap(find.text('Undo group').first);
    await tester.pumpAndSettle();
    await tapText(tester, 'Cancel');

    expect(api.calls, isEmpty);
    expect(find.text('Group 1, 4-6'), findsOneWidget);
  });

  testWidgets('an undone group leaves the detail', (tester) async {
    useSize(tester, screenSizes['tablet']!);
    final api = await open(tester);
    await openDetail(tester);

    await tester.tap(find.text('Undo group').first);
    await tester.pumpAndSettle();
    await giveReason(tester, 'Grupo mal hecho');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Undo group'),
      ),
    );
    await tester.pumpAndSettle();

    expect(api.calls, ['dissolve g1: Grupo mal hecho']);
    expect(find.text('Group 1, 4-6'), findsNothing);
    expect(find.text('Group 2, 4-6'), findsOneWidget);
    expect(find.text('Group 1 undone.'), findsOneWidget);
  });

  testWidgets('clearing needs the reason and the event name typed', (
    tester,
  ) async {
    useSize(tester, screenSizes['desktop']!);
    final api = await open(tester);
    await openDetail(tester);

    await tester.tap(find.text('Clear the competition'));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    final confirm = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(FilledButton, 'Clear the competition'),
    );
    await tester.enterText(fields.first, 'Ensayo terminado');
    await tester.enterText(fields.last, 'Fase');
    await tester.pump();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    await tester.enterText(fields.last, 'Fase 1');
    await tester.pump();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(api.calls, ['clear e0: Ensayo terminado']);
    expect(find.text('No groups yet.'), findsOneWidget);
    expect(
      find.text('Competition cleared: 2 groups and 1 team deleted.'),
      findsOneWidget,
    );
  });

  testWidgets('a match gone meanwhile reloads and says so', (tester) async {
    useSize(tester, screenSizes['desktop']!);
    final api = await open(tester);
    await openDetail(tester);
    api.error = dioError(404);

    await tester.tap(find.text('Restart').first);
    await tester.pumpAndSettle();
    await giveReason(tester, 'Prueba');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Restart'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('The event changed meanwhile; it has been reloaded.'),
      findsOneWidget,
    );
  });

  testWidgets('the list goes page by page', (tester) async {
    useSize(tester, screenSizes['desktop']!);
    final api = await open(tester, total: 45);

    expect(find.text('Page 1 of 3'), findsOneWidget);
    await tapText(tester, 'Next');
    expect(find.text('Fase 1 página 2'), findsOneWidget);
    expect(find.text('Page 2 of 3'), findsOneWidget);
    expect(api.pages, [0, 1]);
  });
}
