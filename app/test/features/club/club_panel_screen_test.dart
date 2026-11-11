import 'dart:typed_data';

import 'package:brackety/core/download/file_download.dart';
import 'package:brackety/features/club/data/club_models.dart';
import 'package:brackety/features/club/data/club_repository.dart';
import 'package:brackety/features/club/state/club_providers.dart';
import 'package:brackety/core/upload/file_upload.dart';
import 'package:brackety/features/club/ui/club_panel_screen.dart';
import 'package:brackety/features/club/ui/settings_tab.dart';
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
  final savedMatReferees = <List<String?>>[];
  final savedRules = <(Duration, int)>[];
  final savedCategories = <List<EventCategory>>[];
  final savedParticipantCategories = <String?>[];
  final savedParticipantOrganizations = <String?>[];
  final savedOrganizations = <List<Organization>>[];

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
    String? organizationId,
  }) async {
    savedParticipantCategories.add(categoryId);
    savedParticipantOrganizations.add(organizationId);
  }

  @override
  Future<List<Organization>> saveOrganizations(
    String eventId,
    List<Organization> organizations,
  ) async {
    _refuse();
    savedOrganizations.add(organizations);
    return [
      for (final (i, o) in organizations.indexed)
        Organization(id: o.id ?? 'o$i', name: o.name, shortName: o.shortName),
    ];
  }

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
    required List<String?> matReferees,
    required Duration matchLength,
    required int pointsLimit,
  }) async {
    _refuse();
    savedMatReferees.add(matReferees);
    savedRules.add((matchLength, pointsLimit));
    return current = EventSettings(
      name: name,
      date: date,
      matReferees: matReferees,
      referees: current.referees,
      categories: current.categories,
      matchLength: matchLength,
      pointsLimit: pointsLimit,
      organizations: current.organizations,
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
  );

  final settings = EventSettings(
    name: 'Fase 1',
    date: DateTime(2026, 11, 14),
    matReferees: const ['r1', null],
    referees: const [StaffMember(id: 'r1', username: 'arbitro1')],
    matchLength: const Duration(minutes: 3),
    pointsLimit: 15,
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
          eventSettingsProvider.overrideWith(
            (ref, _) async => repository is FakeClubRepository
                ? repository.current
                : settings,
          ),
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
                matchesInReview: 1,
              ),
              MatOverview(
                id: 'm2',
                number: 2,
                groups: 0,
                pendingMatches: 0,
                matchInProgress: false,
                remaining: Duration.zero,
                estimatedEnd: DateTime(2026, 11, 14, 9),
              ),
              MatOverview(
                id: 'm3',
                number: 3,
                referee: 'arbitro3',
                groups: 1,
                pendingMatches: 1,
                matchInProgress: false,
                remaining: const Duration(minutes: 3),
                estimatedEnd: DateTime(2026, 11, 14, 9, 3),
              ),
            ],
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
      expect(find.textContaining('1 group · 1 pending match'), findsOneWidget);
      expect(find.textContaining('Estimated end 11:30'), findsOneWidget);
      expect(find.textContaining('1 match under review'), findsOneWidget);
      // Nothing left on mat 2: no estimated end.
      expect(find.text('Mat 2 · No referee'), findsOneWidget);
      expect(find.textContaining('Estimated end 9:00'), findsNothing);
      // The card in review keeps its text readable on the warning colour.
      final review = tester.widget<Text>(
        find.textContaining('1 match under review'),
      );
      final colors = BracketyColors.of(
        tester.element(find.textContaining('1 match under review')),
      );
      expect(review.style?.color, colors.onWarningContainer);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a minor without the guardian is flagged on $device', (
      tester,
    ) async {
      await pumpPanel(tester, size);

      await tester.tap(find.text('Entries'));
      await tester.pumpAndSettle();

      expect(find.text('Guardian missing'), findsOneWidget);
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

  testWidgets('the club adds the clubs taking part in Settings', (
    tester,
  ) async {
    final repository = FakeClubRepository(settings);
    await pumpPanel(tester, const Size(800, 1280), repository: repository);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Add club'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.textContaining('No clubs yet'), findsOneWidget);

    await tester.tap(find.text('Add club'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Club name'),
      'Club Yoseikan Sevilla',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Short name (optional)'),
      'YSE',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final saved = repository.savedOrganizations.single.single;
    expect(
      (saved.id, saved.name, saved.shortName),
      (null, 'Club Yoseikan Sevilla', 'YSE'),
    );
    expect(find.text('Club Yoseikan Sevilla'), findsOneWidget);
  });

  testWidgets('a participant gets their club in the form', (tester) async {
    final repository = FakeClubRepository(
      EventSettings(
        name: settings.name,
        date: settings.date,
        matReferees: settings.matReferees,
        referees: settings.referees,
        categories: settings.categories,
        matchLength: settings.matchLength,
        pointsLimit: settings.pointsLimit,
        organizations: const [
          Organization(id: 'o1', name: 'Club Yoseikan Sevilla'),
        ],
      ),
    );
    await pumpPanel(tester, const Size(800, 1280), repository: repository);
    await tester.tap(find.text('Entries'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lucia Test'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('No club'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Club Yoseikan Sevilla').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('The legal guardian agrees'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(repository.savedParticipantOrganizations, ['o1']);
  });

  testWidgets('a settings change saves on its own, without a button', (
    tester,
  ) async {
    final repository = FakeClubRepository(settings);
    await pumpPanel(tester, const Size(800, 1280), repository: repository);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Save'), findsNothing);
    expect(find.text('Groups per mat at once'), findsNothing);
    await tester.tap(find.text('Add mat'));
    await tester.pumpAndSettle();

    expect(repository.savedMatReferees, [
      ['r1', null, null],
    ]);
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('removing the last mat asks first', (tester) async {
    final repository = FakeClubRepository(settings);
    await pumpPanel(tester, const Size(800, 1280), repository: repository);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove the last mat'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mat 2 is removed'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.savedMatReferees, isEmpty);

    await tester.tap(find.text('Remove the last mat'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remove the last mat'));
    await tester.pumpAndSettle();
    expect(repository.savedMatReferees, [
      ['r1'],
    ]);
  });

  testWidgets('a refused change explains why and shows the saved value', (
    tester,
  ) async {
    final repository = FakeClubRepository(settings)..refuseWith = 409;
    await pumpPanel(tester, const Size(800, 1280), repository: repository);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add mat'));
    await tester.pumpAndSettle();

    expect(
      find.text('Not possible: there are groups that depend on it.'),
      findsOneWidget,
    );
    expect(find.text('Mat 3 · Referee'), findsNothing);
  });

  testWidgets('the club sets the match length and the points limit', (
    tester,
  ) async {
    final repository = FakeClubRepository(settings);
    await pumpPanel(tester, const Size(800, 1280), repository: repository);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    final length = find.widgetWithText(TextFormField, 'Match length (min:s)');
    final limit = find.widgetWithText(
      TextFormField,
      'Points that end the match',
    );
    expect(find.text('3:00'), findsOneWidget);

    await tester.enterText(length, '25:00');
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('between 0:30 and 20:00'), findsOneWidget);
    expect(repository.savedRules, isEmpty);

    await tester.enterText(length, '2:30');
    await tester.enterText(limit, '10');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(repository.savedRules.last, (
      const Duration(minutes: 2, seconds: 30),
      10,
    ));
  });

  testWidgets('a match length refused by a started match says why', (
    tester,
  ) async {
    final repository = FakeClubRepository(settings)..refuseWith = 409;
    await pumpPanel(tester, const Size(800, 1280), repository: repository);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Match length (min:s)'),
      '4:00',
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(
      find.text('It cannot change now: a match is in progress or has started.'),
      findsOneWidget,
    );
    expect(find.text('3:00'), findsOneWidget);
  });

  test('match lengths are read as minutes and seconds', () {
    expect(parseMatchLength('3:00'), const Duration(minutes: 3));
    expect(parseMatchLength('3'), const Duration(minutes: 3));
    expect(parseMatchLength(' 0:30 '), const Duration(seconds: 30));
    expect(parseMatchLength('20:00'), const Duration(minutes: 20));
    for (final bad in ['0:29', '20:01', '3:60', '3:5', 'tres', '']) {
      expect(parseMatchLength(bad), isNull, reason: bad);
    }
    expect(formatMatchLength(const Duration(minutes: 2, seconds: 5)), '2:05');
  });

  Future<void> openCategories(WidgetTester tester) async {
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Add category'),
      200,
      // The settings list, not the text fields' own scrollables.
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
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

  for (final MapEntry(key: device, value: size) in sizes.entries) {
    testWidgets(
      'the whole event downloads as a zip with the server name on $device',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final server = _FileServer();
        final saved = <(String, String)>[];
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              clubRepositoryProvider.overrideWithValue(
                ClubRepository(Dio()..httpClientAdapter = server),
              ),
              saveFileProvider.overrideWithValue(
                (name, bytes, mimeType) async => saved.add((name, mimeType)),
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
              home: Scaffold(
                appBar: AppBar(actions: const [ClubExportMenu(eventId: 'e1')]),
              ),
            ),
          ),
        );

        await tester.tap(find.byTooltip('Export'));
        await tester.pumpAndSettle();
        expect(find.text('Standings (CSV)'), findsOneWidget);
        await tester.tap(find.text('The whole event (.zip)'));
        await tester.pumpAndSettle();

        expect(server.paths, ['/api/v1/events/e1/export/full']);
        expect(saved, [('fase-1-2026-11-14.zip', 'application/zip')]);
      },
    );
  }

  Future<_FileServer> openImport(
    WidgetTester tester,
    _FileServer server,
  ) async {
    tester.view.physicalSize = sizes['tablet']!;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clubRepositoryProvider.overrideWithValue(
            ClubRepository(Dio()..httpClientAdapter = server),
          ),
          pickFilesProvider.overrideWithValue(
            ({required accept, required multiple}) async => [
              const PickedFile(name: 'fase-1.zip', bytes: [80, 75, 3, 4]),
            ],
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
          home: Scaffold(
            appBar: AppBar(actions: const [ClubExportMenu(eventId: 'e1')]),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Export'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import results from the sports hall'));
    await tester.pumpAndSettle();
    return server;
  }

  testWidgets('the hall results are counted, confirmed and then imported', (
    tester,
  ) async {
    final server = await openImport(tester, _FileServer());

    expect(server.imports, [true]);
    expect(find.textContaining('3 groups, 18 matches'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await tester.pumpAndSettle();

    expect(server.imports, [true, false]);
    expect(find.text('Results imported.'), findsOneWidget);
  });

  testWidgets('results into an event with its own groups are refused', (
    tester,
  ) async {
    await openImport(tester, _FileServer()..importStatus = 409);

    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.textContaining('already has groups of its own'),
      findsOneWidget,
    );
  });
}

/// Answers any download with a small file named by Content-Disposition, like the API.
class _FileServer implements HttpClientAdapter {
  final paths = <String>[];

  /// The dryRun flag of each results import.
  final imports = <bool>[];
  int importStatus = 200;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.uri.path.endsWith('/import/results')) {
      imports.add(options.uri.queryParameters['dryRun'] == 'true');
      return ResponseBody.fromString(
        importStatus == 200
            ? '{"alreadyImported":false,"newParticipants":2,"newMats":0,'
                  '"newCategories":0,"newOrganizations":0,"teams":0,'
                  '"groups":3,"matches":18,"actions":240}'
            : '{"code":"RESULTS_CONFLICT"}',
        importStatus,
        headers: {
          'content-type': ['application/json'],
        },
      );
    }
    paths.add(options.uri.path);
    final name = options.uri.path.endsWith('/full')
        ? 'fase-1-2026-11-14.zip'
        : 'fase-1-2026-11-14.brackety';
    return ResponseBody.fromString(
      '{"schemaVersion":1}',
      200,
      headers: {
        'content-disposition': ['attachment; filename="$name"'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
