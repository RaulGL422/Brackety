import 'package:brackety/features/club/data/club_models.dart';
import 'package:brackety/features/club/state/club_providers.dart';
import 'package:brackety/features/events/data/my_event.dart';
import 'package:brackety/features/events/state/events_providers.dart';
import 'package:brackety/features/events/ui/events_screen.dart';
import 'package:brackety/features/league/data/league_models.dart';
import 'package:brackety/features/league/data/league_repository.dart';
import 'package:brackety/features/league/state/league_providers.dart';
import 'package:brackety/features/league/ui/league_settings_dialog.dart';
import 'package:brackety/features/league/ui/league_tab.dart';
import 'package:brackety/features/league/ui/phase_switcher.dart';
import 'package:brackety/features/league/ui/reenrol_dialog.dart';
import 'package:brackety/features/mat/data/mat_board.dart';
import 'package:brackety/l10n/gen/app_localizations.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeLeagueRepository extends Fake implements LeagueRepository {
  FakeLeagueRepository([this.saved]);

  final reenrolled = <(List<String>, bool)>[];
  final League? saved;
  Podium? savedPodium;
  List<CategoryPodium>? savedCategoryPodiums;

  @override
  Future<League> save(
    String eventId, {
    required String name,
    required Podium podium,
    required List<CategoryPodium> categoryPodiums,
  }) async {
    savedPodium = podium;
    savedCategoryPodiums = categoryPodiums;
    return saved!;
  }

  @override
  Future<int> reenrol(
    String eventId,
    List<String> personIds, {
    required bool guardianConsent,
  }) async {
    reenrolled.add((personIds, guardianConsent));
    return personIds.length;
  }
}

void main() {
  const sizes = {
    'phone': Size(360, 800),
    'tablet': Size(800, 1280),
    'desktop': Size(1440, 900),
  };

  MyEvent phase(String id, int number, Set<EventRole> roles) => MyEvent(
    id: id,
    name: 'Liga Yoseikan · Fase $number',
    date: DateTime(2026, 11, 14).add(Duration(days: 28 * (number - 1))),
    roles: roles,
    leagueId: 'l1',
    leagueName: 'Liga Yoseikan',
    phaseNumber: number,
  );

  final league = League(
    name: 'Liga Yoseikan',
    podium: const Podium(firsts: 2, seconds: 2, thirds: 3),
    categoryPodiums: const [],
    phases: [
      LeaguePhase(
        eventId: 'e1',
        number: 1,
        name: 'Liga Yoseikan · Fase 1',
        date: DateTime(2026, 11, 14),
        discipline: Discipline.tambo,
        participants: 40,
      ),
      LeaguePhase(
        eventId: 'e2',
        number: 2,
        name: 'Liga Yoseikan · Fase 2',
        date: DateTime(2026, 12, 12),
        discipline: Discipline.tambo,
        participants: 1,
      ),
    ],
    categoryNames: const ['4-7', '8-11'],
    availableDisciplines: const {Discipline.tambo},
  );

  final standings = LeagueStandings.fromJson({
    'phases': [
      {'eventId': 'e1', 'number': 1, 'name': 'Fase 1'},
      {'eventId': 'e2', 'number': 2, 'name': 'Fase 2'},
    ],
    'rows': [
      {
        'categoryName': '8-11',
        'position': 1,
        'medal': 1,
        'personId': 'a',
        'firstName': 'Zoe',
        'lastName': 'Test',
        'organizationName': 'Club Norte',
        'phases': [
          {'attendancePoints': 10, 'matchPoints': 20},
          {'attendancePoints': 10, 'matchPoints': 5},
        ],
        'total': 45,
        'warnings': 3,
        'disqualifications': 1,
        'eventId': 'e2',
        'participantId': 'pz',
      },
      {
        'categoryName': '4-7',
        'position': 1,
        'medal': null,
        'personId': 'b',
        'firstName': 'Bea',
        'lastName': 'Test',
        'organizationName': null,
        'phases': [
          {'attendancePoints': 10, 'matchPoints': 0},
          null,
        ],
        'total': 10,
      },
    ],
  });

  Widget app(Widget home, {List<Override> overrides = const []}) =>
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          builder: (_, child) => ToastHost(child: child!),
          theme: lightTheme(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...coreLocalizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );

  void setSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  test('events group by league with phases in order', () {
    final grouped = byLeague([
      phase('e2', 2, {EventRole.club}),
      MyEvent(
        id: 'x',
        name: 'Open',
        date: DateTime(2026),
        roles: {EventRole.referee},
      ),
      phase('e1', 1, {EventRole.club}),
    ]);

    expect(grouped.map((l) => l.map((e) => e.id)).toList(), [
      ['e1', 'e2'],
      ['x'],
    ]);
  });

  test('an event from an older server is phase 1 of its own league', () {
    final event = MyEvent.fromJson({
      'id': 'e9',
      'name': 'Copa',
      'date': '2026-11-14',
      'roles': ['CLUB'],
    });

    expect(
      (event.leagueId, event.leagueName, event.phaseNumber),
      ('e9', 'Copa', 1),
    );
  });

  testWidgets('the phase switcher hides on a phase the account does not run', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const Scaffold(body: PhaseSwitcher(eventId: 'e3')),
        overrides: [
          myEventsProvider.overrideWith(
            (ref) async => [
              phase('e1', 1, {EventRole.club}),
              phase('e2', 2, {EventRole.club}),
              phase('e3', 3, {EventRole.referee}),
            ],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Phase'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final MapEntry(key: device, value: size) in sizes.entries) {
    testWidgets('my events show one card per league on $device', (
      tester,
    ) async {
      setSize(tester, size);
      await tester.pumpWidget(
        app(
          const EventsScreen(),
          overrides: [
            myEventsProvider.overrideWith(
              (ref) async => [
                phase('e2', 2, {EventRole.club}),
                phase('e1', 1, {EventRole.club, EventRole.grouper}),
              ],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Liga Yoseikan'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Liga Yoseikan · Fase 1')).dy,
        lessThan(tester.getTopLeft(find.text('Liga Yoseikan · Fase 2')).dy),
      );
      // The club enters the league, then its phases; a helper still sees their phase.
      expect(find.text('Open the league'), findsOneWidget);
      expect(find.text('Club panel'), findsNothing);
      expect(find.text('Make groups'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the league tab lists phases and medals on $device', (
      tester,
    ) async {
      setSize(tester, size);
      await tester.pumpWidget(
        app(
          const Scaffold(body: LeagueTab(eventId: 'e2')),
          overrides: [
            leagueProvider.overrideWith((ref, _) async => league),
            leagueStandingsProvider.overrideWith((ref, _) async => standings),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Liga Yoseikan'), findsOneWidget);
      expect(find.text('This phase'), findsNothing);
      expect(find.textContaining('40 entries'), findsOneWidget);
      expect(find.text('Zoe Test'), findsOneWidget);
      expect(
        find.textContaining(
          'Phase 1: 30 (10 for attending + 20 in matches)\n'
          'Phase 2: 15 (10 for attending + 5 in matches)',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Phase 2: not entered'), findsOneWidget);
      // Warnings and disqualifications stand out on their own.
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byIcon(Icons.block), findsOneWidget);
      // One heading per category, in the league's order.
      expect(find.text('8-11 · 1 person'), findsOneWidget);
      expect(find.text('4-7 · 1 person'), findsOneWidget);
      expect(find.byTooltip('Gold'), findsOneWidget);

      await tester.ensureVisible(find.text('All categories'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All categories'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('4-7').last);
      await tester.pumpAndSettle();
      expect(find.text('Zoe Test'), findsNothing);
      expect(find.text('Bea Test'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'a person opened from the league shows the warnings of every phase',
    (tester) async {
      setSize(tester, sizes['phone']!);
      RecordMatch fought(String id, String rival, List<Incident> incidents) =>
          RecordMatch(
            matchId: id,
            matNumber: 1,
            groupNumber: 2,
            status: MatchStatus.finished,
            red: true,
            asGhost: false,
            rival: rival,
            points: 5,
            rivalPoints: 15,
            warnings: 1,
            oneHandWarnings: 0,
            disqualified: false,
            rivalDisqualified: false,
            incidents: incidents,
          );
      String? opened;
      await tester.pumpWidget(
        app(
          const Scaffold(body: LeagueTab(eventId: 'e2')),
          overrides: [
            leagueProvider.overrideWith((ref, _) async => league),
            leagueStandingsProvider.overrideWith((ref, _) async => standings),
            participantRecordProvider.overrideWith(
              (ref, key) async => ParticipantRecord(
                standing: const StandingRow(
                  position: 1,
                  participantId: 'pz',
                  firstName: 'Zoe',
                  lastName: 'Test',
                  age: 9,
                  categoryName: '8-11',
                  attendancePoints: 10,
                  matchPoints: 5,
                  total: 15,
                  matches: 1,
                ),
                matches: const [],
              ),
            ),
            leagueRecordProvider.overrideWith((ref, key) async {
              opened = key.personId;
              return LeagueRecord([
                (
                  number: 1,
                  name: 'Fase 1',
                  matches: [
                    fought('m1', 'Ana Test', const [
                      Incident(
                        kind: IncidentKind.warning,
                        reason: 'Agarre',
                        clock: Duration(seconds: 35),
                      ),
                    ]),
                  ],
                ),
                (
                  number: 2,
                  name: 'Fase 2',
                  matches: [
                    fought('m2', 'Eva Test', const [
                      Incident(
                        kind: IncidentKind.disqualification,
                        reason: 'Mordisco',
                        clock: Duration(seconds: 70),
                      ),
                    ]),
                  ],
                ),
              ]);
            }),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Zoe Test'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zoe Test'));
      await tester.pumpAndSettle();
      expect(opened, 'a');
      await tester.tap(
        find.text('1 warning in the league · 1 disqualification'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Phase 1 · Fase 1'), findsOneWidget);
      expect(find.text('Warning · 0:35 · Agarre'), findsOneWidget);
      expect(find.text('Phase 2 · Fase 2'), findsOneWidget);
      expect(find.text('Disqualified · 1:10 · Mordisco'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'podiums are set with one tap, and a category only when it differs',
    (tester) async {
      setSize(tester, sizes['phone']!);
      final repository = FakeLeagueRepository(league);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showLeagueSettings(context, 'e2', league),
                child: const Text('open'),
              ),
            ),
          ),
          overrides: [leagueRepositoryProvider.overrideWithValue(repository)],
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // The league's 2·2·3 is no usual one: "Other" with its counters.
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Other'))
            .selected,
        isTrue,
      );
      await tester.tap(find.text('1 gold · 1 silver · 2 bronze'));
      await tester.pumpAndSettle();
      expect(find.text('As the general one (1·1·2)'), findsNWidgets(2));

      await tester.ensureVisible(find.text('As the general one (1·1·2)').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('As the general one (1·1·2)').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Its own').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.text('1 gold · 1 silver · 1 bronze').last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 gold · 1 silver · 1 bronze').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final general = repository.savedPodium!;
      expect((general.firsts, general.seconds, general.thirds), (1, 1, 2));
      final own = repository.savedCategoryPodiums!.single;
      expect(own.categoryName, '4-7');
      expect(
        (own.podium.firsts, own.podium.seconds, own.podium.thirds),
        (1, 1, 1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('re-entering a minor needs the guardians consent', (
    tester,
  ) async {
    setSize(tester, sizes['phone']!);
    final repository = FakeLeagueRepository();
    await tester.pumpWidget(
      app(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showReenrolDialog(context, 'e2'),
              child: const Text('open'),
            ),
          ),
        ),
        overrides: [
          leagueRepositoryProvider.overrideWithValue(repository),
          leagueCandidatesProvider.overrideWith(
            (ref, _) async => const [
              LeagueCandidate(
                personId: 'p1',
                firstName: 'Lucia',
                lastName: 'Test',
                age: 7,
                lastPhase: 1,
                categoryName: '4-7',
              ),
              LeagueCandidate(
                personId: 'p2',
                firstName: 'Mario',
                lastName: 'Test',
                age: 30,
                lastPhase: 1,
              ),
            ],
          ),
          participantsProvider.overrideWith((ref, _) async => <Participant>[]),
        ],
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Select all (2)'));
    await tester.pumpAndSettle();
    final enter = find.widgetWithText(FilledButton, 'Enter (2)');
    expect(tester.widget<FilledButton>(enter).onPressed, isNull);

    await tester.tap(
      find.text('I have the consent of the guardians of the selected minors'),
    );
    await tester.pumpAndSettle();
    await tester.tap(enter);
    await tester.pumpAndSettle();

    expect(repository.reenrolled.single.$2, isTrue);
    expect(repository.reenrolled.single.$1, unorderedEquals(['p1', 'p2']));
    expect(find.text('2 entered'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
