import 'package:brackety_admin/features/events/data/events_api.dart';
import 'package:brackety_admin/features/events/state/events_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

class FakeEventsApi implements EventsApi {
  FakeEventsApi({this.total = 1, this.package});

  final int total;

  /// The hall laptop's package; null on a server without one.
  final String? package;
  final pages = <int>[];
  final calls = <String>[];
  DioException? error;
  var groups = [group('g1', 1), group('g2', 2)];
  var teams = <AdminTeam>[];

  static AdminGroup group(String id, int number) => AdminGroup(
    id: id,
    number: number,
    category: '4-6',
    matNumber: number,
    createdBy: 'Ana López (ayudante1)',
    members: const [
      AdminSide(name: 'Leo Molina'),
      AdminSide(name: 'Noa Vázquez'),
      AdminSide(name: 'Ana Ruiz'),
      AdminSide(name: 'Zoe Gil', ghost: true),
    ],
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
        red: const AdminSide(
          teamNumber: 2,
          members: [
            AdminMember(name: 'Ana'),
            AdminMember(name: 'Bea'),
            AdminMember(name: 'Carla', ghost: true),
          ],
        ),
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
    mats: [
      AdminMat(
        id: 'm1',
        number: 1,
        referee: 'arbitro1',
        plan: [
          AdminPlannedMatch(
            matchId: 'g1-m2',
            groupNumber: 1,
            category: '4-6',
            startsAt: DateTime(2026, 11, 14, 9, 30),
            red: const AdminSide(name: 'Leo Molina'),
            blue: const AdminSide(name: 'Zoe Gil', ghost: true),
          ),
        ],
      ),
      const AdminMat(id: 'm2', number: 2),
    ],
    groups: groups,
    teams: teams,
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
  Future<void> moveGroup(String eventId, String groupId, String matId) async =>
      calls.add('moveGroup $groupId $matId');

  @override
  Future<void> moveMatch(String eventId, String matchId, String matId) async =>
      calls.add('moveMatch $matchId $matId');

  @override
  Future<void> reorder(
    String eventId,
    String groupId,
    List<String> matchIds,
  ) async => calls.add('reorder $groupId');

  @override
  Future<void> moveTeamMember(
    String eventId, {
    required String participantId,
    required String fromTeamId,
    required String toTeamId,
  }) async => calls.add('member $participantId $fromTeamId $toTeamId');

  @override
  Future<void> waiveRest(String eventId, String matchId) async =>
      calls.add('waiveRest $matchId');

  @override
  Future<String?> resetPackage() async => package;

  @override
  Future<void> resetEvent(String reason) async =>
      calls.add('resetEvent: $reason');

  @override
  Future<Cleared> clearCompetition(String eventId, String reason) async {
    calls.add('clear $eventId: $reason');
    final cleared = (groups: groups.length, teams: 1);
    groups = [];
    teams = [];
    return cleared;
  }
}

void main() {
  Future<FakeEventsApi> open(
    WidgetTester tester, {
    int total = 1,
    String? package,
  }) async {
    final api = FakeEventsApi(total: total, package: package);
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
      expect(find.text('Made by Ana López (ayudante1)'), findsWidgets);
      expect(find.text('Leo Molina'), findsWidgets);
      expect(find.text('Team 2 (Ana, Bea, Carla · wildcard)'), findsWidgets);
      expect(find.text('Zoe Gil · wildcard'), findsWidgets);
      expect(find.text('Nothing pending'), findsOneWidget);
      expect(find.text('15–3'), findsWidgets);
      expect(find.text('1 pending match, starting at 09:30'), findsOneWidget);

      // Mat 1 unfolds the order its referee would get the matches in.
      await tester.tap(find.text('Mat 1: arbitro1'));
      await tester.pumpAndSettle();
      expect(find.text('09:30'), findsOneWidget);
      expect(find.text('Zoe Gil · wildcard'), findsWidgets);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Back to the events'));
      await tester.pumpAndSettle();
      expect(find.text('Fase 1 página 1'), findsOneWidget);
    });
  }

  testWidgets('without a package there is no event reset', (tester) async {
    useSize(tester, screenSizes['desktop']!);
    await open(tester);

    expect(find.text('Start the event again from the package'), findsNothing);
  });

  for (final MapEntry(key: device, value: size) in screenSizes.entries) {
    testWidgets(
      'the hall laptop starts the event again, typing the word, on $device',
      (tester) async {
        useSize(tester, size);
        final api = await open(tester, package: 'fase-1.brackety');

        await tester.tap(find.text('Start the event again from the package'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('fase-1.brackety is loaded again'),
          findsOneWidget,
        );
        final confirm = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(
            FilledButton,
            'Start the event again from the package',
          ),
        );
        await giveReason(tester, 'Pruebas acabadas');
        expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
        await tester.enterText(
          find
              .descendant(
                of: find.byType(AlertDialog),
                matching: find.byType(TextField),
              )
              .last,
          'REINICIAR',
        );
        await tester.pump();
        await tester.tap(confirm);
        await tester.pumpAndSettle();

        expect(api.calls, ['resetEvent: Pruebas acabadas']);
        expect(
          find.text('Event started again from the package.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
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

  testWidgets('a pending match can skip the rest, after asking', (
    tester,
  ) async {
    useSize(tester, screenSizes['desktop']!);
    final api = await open(tester);
    await openDetail(tester);

    await tester.tap(find.byTooltip('Change').first);
    await tester.pumpAndSettle();
    await tapText(tester, 'Let it start without waiting for the rest');
    expect(find.text('Start without the least rest?'), findsOneWidget);
    await tapText(tester, 'Yes, allow');

    expect(api.calls, ['waiveRest g1-m2']);
  });

  testWidgets('a group only moves to a mat with a referee', (tester) async {
    useSize(tester, screenSizes['desktop']!);
    final api = await open(tester);
    await openDetail(tester);

    await tester.tap(find.text('Move the group to another mat').first);
    await tester.pumpAndSettle();
    // Mat 2 has no referee and mat 1 is its own.
    expect(find.text('No other mat has a referee.'), findsOneWidget);
    expect(api.calls, isEmpty);
  });

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

  testWidgets('teams without a group are cleared too, on a phone', (
    tester,
  ) async {
    useSize(tester, screenSizes['phone']!);
    final api = FakeEventsApi()
      ..groups = []
      ..teams = [
        const AdminTeam(
          id: 't1',
          number: 1,
          category: '9-12',
          members: [
            AdminTeamPerson(participantId: 'p1', name: 'Ana'),
            AdminTeamPerson(participantId: 'p2', name: 'Bea'),
          ],
        ),
      ];
    await pumpAdmin(
      tester,
      location: '/events',
      overrides: [eventsApiProvider.overrideWithValue(api)],
    );
    await openDetail(tester);

    await tester.tap(find.text('Clear the competition'));
    await tester.pumpAndSettle();
    // The keyboard takes half of the screen.
    tester.view.viewInsets = const FakeViewPadding(bottom: 400);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.first, 'Equipos mal hechos');
    await tester.enterText(fields.last, 'Fase 1');
    await tester.pump();
    final confirm = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(FilledButton, 'Clear the competition'),
    );
    // The buttons stay reachable on a small screen.
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(api.calls, ['clear e0: Equipos mal hechos']);
    expect(tester.takeException(), isNull);
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
