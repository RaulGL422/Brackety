import 'package:brackety/features/club/data/club_models.dart';
import 'package:brackety/features/club/data/club_repository.dart';
import 'package:brackety/features/club/state/club_providers.dart';
import 'package:brackety/features/club/ui/club_panel_screen.dart';
import 'package:brackety/features/club/ui/participant_form.dart';
import 'package:brackety/features/events/data/my_event.dart';
import 'package:brackety/features/events/state/events_providers.dart';
import 'package:brackety/l10n/gen/app_localizations.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Saves settings like the server would, or refuses them with [refuseWith].
class FakeClubRepository extends Fake implements ClubRepository {
  FakeClubRepository(this.current);

  EventSettings current;
  int? refuseWith;
  final savedMaxGroups = <int>[];
  final savedCategories = <List<EventCategory>>[];
  final savedParticipantCategories = <String?>[];

  @override
  Future<void> saveParticipant(
    String eventId, {
    String? participantId,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    required int? heightCm,
    required bool guardianConsent,
    String? categoryId,
  }) async => savedParticipantCategories.add(categoryId);

  @override
  Future<List<EventCategory>> saveCategories(
    String eventId,
    List<EventCategory> categories,
  ) async {
    _refuse();
    savedCategories.add(categories);
    return [
      for (final (i, c) in categories.indexed)
        EventCategory(
          id: c.id ?? 'new$i',
          name: c.name,
          minAge: c.minAge,
          maxAge: c.maxAge,
          teamSize: c.teamSize,
        ),
    ];
  }

  void _refuse() {
    if (refuseWith != null) {
      throw DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: refuseWith,
        ),
      );
    }
  }

  @override
  Future<EventSettings> saveSettings(
    String eventId, {
    required String name,
    required DateTime date,
    required int maxGroupsPerMat,
    required List<String?> matReferees,
  }) async {
    _refuse();
    savedMaxGroups.add(maxGroupsPerMat);
    return current = EventSettings(
      name: name,
      date: date,
      maxGroupsPerMat: maxGroupsPerMat,
      matReferees: matReferees,
      referees: current.referees,
      categories: current.categories,
    );
  }
}

void main() {
  const sizes = {
    'phone': Size(360, 800),
    'tablet': Size(800, 1280),
    'desktop': Size(1440, 900),
  };

  final event = MyEvent(
    id: 'e1',
    name: 'Fase 1',
    date: DateTime(2026, 11, 14),
    roles: {EventRole.club},
    maxGroupsPerMat: 1,
  );

  final settings = EventSettings(
    name: 'Fase 1',
    date: DateTime(2026, 11, 14),
    maxGroupsPerMat: 1,
    matReferees: const ['r1', null],
    referees: const [StaffMember(id: 'r1', username: 'arbitro1')],
    categories: const [
      EventCategory(id: 'c1', name: '4-7', minAge: 4, maxAge: 7),
      EventCategory(id: 'c2', name: '8-11', minAge: 8, maxAge: 11),
      EventCategory(
        id: 'c3',
        name: '15-16',
        minAge: 15,
        maxAge: 16,
        teamSize: 3,
      ),
    ],
  );

  StandingRow row(int position, String name, String categoryId, int total) =>
      StandingRow(
        position: position,
        participantId: name,
        firstName: name,
        lastName: 'Test',
        age: categoryId == 'c1' ? 6 : 9,
        categoryId: categoryId,
        categoryName: categoryId == 'c1' ? '4-7' : '8-11',
        attendancePoints: 10,
        matchPoints: total - 10,
        total: total,
        matches: 2,
      );

  final standings = [
    row(1, 'Zoe', 'c2', 40),
    row(2, 'Bea', 'c1', 25),
    row(3, 'Ana', 'c2', 12),
  ];

  final minor = Participant(
    id: 'p1',
    firstName: 'Lucia',
    lastName: 'Test',
    birthDate: DateTime(2019, 3, 1),
    guardianConsent: false,
    age: 7,
    categoryName: '4-7',
  );

  Future<void> pumpPanel(
    WidgetTester tester,
    Size size, {
    ClubRepository? repository,
    List<StandingRow>? scores,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (repository != null)
            clubRepositoryProvider.overrideWithValue(repository),
          myEventsProvider.overrideWith((ref) async => [event]),
          eventSettingsProvider.overrideWith((ref, _) async => settings),
          standingsProvider.overrideWith((ref, _) async => scores ?? standings),
          participantsProvider.overrideWith((ref, _) async => [minor]),
          matsOverviewProvider.overrideWith(
            (ref, _) async => [
              MatOverview(
                id: 'm1',
                number: 1,
                referee: 'arbitro1',
                groups: 2,
                pendingMatches: 9,
                matchInProgress: true,
                remaining: const Duration(minutes: 20),
                estimatedEnd: DateTime(2026, 11, 14, 11, 30),
              ),
            ],
          ),
        ],
        child: MaterialApp(
          theme: lightTheme(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...coreLocalizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ClubPanelScreen(eventId: 'e1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  double top(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dy;

  for (final MapEntry(key: device, value: size) in sizes.entries) {
    testWidgets('scores filter by category and sort by name on $device', (
      tester,
    ) async {
      await pumpPanel(tester, size);

      expect(find.text('Fase 1'), findsOneWidget);
      expect(top(tester, 'Zoe Test'), lessThan(top(tester, 'Ana Test')));

      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      expect(top(tester, 'Ana Test'), lessThan(top(tester, 'Zoe Test')));

      await tester.tap(find.text('All categories'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('4-7').last);
      await tester.pumpAndSettle();
      expect(find.text('Bea Test'), findsOneWidget);
      expect(find.text('Ana Test'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mats show referee, load and estimated end on $device', (
      tester,
    ) async {
      await pumpPanel(tester, size);

      await tester.tap(find.text('Mats'));
      await tester.pumpAndSettle();

      expect(find.text('Mat 1 · arbitro1'), findsOneWidget);
      expect(
        find.textContaining('2 groups · 9 pending matches'),
        findsOneWidget,
      );
      expect(find.text('Estimated end 11:30'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a minor cannot be saved without the guardian on $device', (
      tester,
    ) async {
      await pumpPanel(tester, size);

      await tester.tap(find.text('Entries'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lucia Test'));
      await tester.pumpAndSettle();

      FilledButton save() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save'),
      );
      expect(save().onPressed, isNull);
      expect(
        find.text(
          "The student's data is handled according to the privacy policy.",
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('The legal guardian agrees'));
      await tester.pump();
      expect(save().onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a participant can be put in another category than their age', (
    tester,
  ) async {
    final repository = FakeClubRepository(settings);
    await pumpPanel(tester, const Size(800, 1280), repository: repository);
    await tester.tap(find.text('Entries'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lucia Test'));
    await tester.pumpAndSettle();

    expect(find.text('By age'), findsOneWidget);
    await tester.tap(find.text('By age'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('8-11').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('The legal guardian agrees'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(repository.savedParticipantCategories, ['c2']);
  });

  testWidgets('a settings change saves on its own, without a button', (
    tester,
  ) async {
    final repository = FakeClubRepository(settings);
    await pumpPanel(tester, const Size(800, 1280), repository: repository);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Save'), findsNothing);
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();

    expect(repository.savedMaxGroups, [2]);
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('a refused change explains why and shows the saved value', (
    tester,
  ) async {
    final repository = FakeClubRepository(settings)..refuseWith = 409;
    await pumpPanel(tester, const Size(800, 1280), repository: repository);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();

    expect(
      find.text('Not possible: there are groups that depend on it.'),
      findsOneWidget,
    );
    final segments = tester.widget<SegmentedButton<int>>(
      find.byType(SegmentedButton<int>),
    );
    expect(segments.selected, {1});
  });

  Future<void> openCategories(WidgetTester tester) async {
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Add category'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  }

  for (final MapEntry(key: device, value: size) in sizes.entries) {
    testWidgets('the club adds a team category on $device', (tester) async {
      final repository = FakeClubRepository(settings);
      await pumpPanel(tester, size, repository: repository);
      await openCategories(tester);

      expect(find.text('Teams of 3 · Groups of 4'), findsOneWidget);
      expect(find.text('Individual · Groups of 4'), findsNWidgets(2));
      await tester.tap(find.text('Add category'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        '17-19',
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'From'), '17');
      await tester.enterText(find.widgetWithText(TextFormField, 'To'), '19');
      await tester.tap(find.text('By teams'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final saved = repository.savedCategories.single;
      expect(saved, hasLength(4));
      expect(saved.last.name, '17-19');
      expect(saved.last.teamSize, 3);
      expect(find.text('Saved'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a category with ages the wrong way round is not saved', (
    tester,
  ) async {
    final repository = FakeClubRepository(settings);
    await pumpPanel(tester, const Size(800, 1280), repository: repository);
    await openCategories(tester);
    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'X');
    await tester.enterText(find.widgetWithText(TextFormField, 'From'), '12');
    await tester.enterText(find.widgetWithText(TextFormField, 'To'), '10');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(
      find.text('The minimum age cannot be above the maximum.'),
      findsOneWidget,
    );
    expect(repository.savedCategories, isEmpty);
  });

  testWidgets('removing a category in use explains why', (tester) async {
    final repository = FakeClubRepository(settings)..refuseWith = 409;
    await pumpPanel(tester, const Size(800, 1280), repository: repository);
    await openCategories(tester);

    await tester.tap(find.byTooltip('Remove category').last);
    await tester.pumpAndSettle();

    expect(
      find.text('A category with groups or teams can only change its name.'),
      findsOneWidget,
    );
    expect(find.text('Teams of 3 · Groups of 4'), findsOneWidget);
  });

  testWidgets('a team member shows their team in the scores', (tester) async {
    await pumpPanel(
      tester,
      const Size(800, 1280),
      scores: [
        StandingRow(
          position: 4,
          participantId: 'teen',
          firstName: 'Teo',
          lastName: 'Test',
          age: 15,
          categoryId: 'c3',
          categoryName: '15-16',
          attendancePoints: 10,
          matchPoints: 0,
          total: 10,
          matches: 3,
          teamNumber: 2,
        ),
      ],
    );

    expect(find.textContaining('Team 2 · 15 years · 15-16'), findsOneWidget);
  });

  test('age counts whole years up to the day before the birthday', () {
    final birth = DateTime(2019, 11, 14);
    expect(ageOn(birth, DateTime(2026, 11, 13)), 6);
    expect(ageOn(birth, DateTime(2026, 11, 14)), 7);
    expect(ageOn(DateTime(2008, 12, 1), DateTime(2026, 11, 14)), 17);
  });
}
