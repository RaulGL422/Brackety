import 'package:brackety/features/appearance/data/device_prefs.dart';
import 'package:brackety/features/appearance/state/device_prefs_provider.dart';
import 'package:brackety/features/auth/state/auth_providers.dart';
import 'package:brackety/features/events/data/my_event.dart';
import 'package:brackety/features/events/state/events_providers.dart';
import 'package:brackety/features/home/data/league_overview.dart';
import 'package:brackety/features/home/ui/events_screen.dart';
import 'package:brackety/l10n/gen/app_localizations.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/fakes.dart';

const _sizes = {
  'phone': Size(360, 800),
  'tablet': Size(800, 1280),
  'desktop': Size(1440, 900),
};

/// Phase [number] of a six-phase league, in [state].
MyEvent _phase(
  int number,
  PhaseState state, {
  Set<EventRole> roles = const {EventRole.club},
  Set<EventPermission> permissions = const {...EventPermission.values},
}) => MyEvent(
  id: 'p$number',
  name: 'Liga Yoseikan · Fase $number',
  date: DateTime(2026, 9, 1).add(Duration(days: 28 * number)),
  roles: roles,
  permissions: permissions,
  leagueId: 'l1',
  leagueName: 'Liga Yoseikan',
  phaseNumber: number,
  phaseState: state,
);

/// A standalone event: a league of one phase.
MyEvent _single(
  String id,
  String name,
  DateTime date,
  PhaseState state, {
  Set<EventRole> roles = const {EventRole.club},
  Set<EventPermission> permissions = const {...EventPermission.values},
  int? mat,
}) => MyEvent(
  id: id,
  name: name,
  date: date,
  roles: roles,
  permissions: permissions,
  matId: mat == null ? null : 'm$mat',
  matNumber: mat,
  phaseState: state,
);

/// A club with a six-phase league on its fourth phase, an event to come and four finished.
final _clubEvents = [
  for (var n = 1; n <= 6; n++)
    _phase(
      n,
      n < 4
          ? PhaseState.finished
          : n == 4
          ? PhaseState.inProgress
          : PhaseState.notStarted,
    ),
  _single(
    'g1',
    'Open de Grappling',
    DateTime(2026, 12, 20),
    PhaseState.notStarted,
  ),
  for (var i = 1; i <= 4; i++)
    _single('f$i', 'Copa $i', DateTime(2026, 6, i), PhaseState.finished),
];

void main() {
  Future<void> pump(
    WidgetTester tester,
    List<MyEvent> events, {
    Size size = const Size(360, 800),
    bool organizer = true,
    DateTime? today,
    DevicePrefs prefs = const DevicePrefs(),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget page(String text) => Scaffold(body: Text(text));
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const EventsScreen()),
        GoRoute(
          path: '/events/:id/club',
          builder: (_, s) => page('Panel ${s.pathParameters['id']}'),
        ),
        GoRoute(
          path: '/events/:id/categories',
          builder: (_, s) => page('Groups ${s.pathParameters['id']}'),
        ),
        GoRoute(
          path: '/mats/:id',
          builder: (_, s) => page('Mat ${s.pathParameters['id']}'),
        ),
        GoRoute(
          path: '/leagues/:id',
          builder: (_, s) => page('League ${s.pathParameters['id']}'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myEventsProvider.overrideWith((ref) async => events),
          accountOverride(organizer ? clubAccount : testAccount()),
          savedDevicePrefsProvider.overrideWithValue(prefs),
          todayProvider.overrideWithValue(today ?? DateTime(2026, 11, 26)),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: lightTheme(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...coreLocalizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).first);
    await tester.pumpAndSettle();
  }

  group('sections', () {
    test('a league goes where its phase that matters now is', () {
      final sections = overviewOf(_clubEvents);

      expect(sections.live.single.featured.id, 'p4');
      expect(sections.upcoming.single.featured.id, 'g1');
      // The finished, latest first.
      expect(sections.finished.map((l) => l.featured.id), [
        'f4',
        'f3',
        'f2',
        'f1',
      ]);
    });

    test('a league with no phase started waits for its first', () {
      final league = LeagueOverview([
        _phase(2, PhaseState.notStarted),
        _phase(1, PhaseState.notStarted),
      ]);

      expect((league.stage, league.featured.id), (LeagueStage.upcoming, 'p1'));
    });

    test('a referee mat opens only while the phase is on', () {
      MyEvent referee(PhaseState state) => _single(
        'r',
        'Open',
        DateTime(2026, 12, 20),
        state,
        roles: {EventRole.referee},
        permissions: {EventPermission.ownMat},
        mat: 2,
      );

      expect(tasksOf(referee(PhaseState.notStarted)), isEmpty);
      expect(tasksOf(referee(PhaseState.inProgress)), [EventTask.mat]);
    });
  });

  for (final MapEntry(key: device, value: size) in _sizes.entries) {
    testWidgets('the club sees now, next and finished on $device', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, _clubEvents, size: size);

      expect(
        tester.getTopLeft(find.text('On now').first).dy,
        lessThan(tester.getTopLeft(find.text('Coming up')).dy),
      );
      expect(find.text('Liga Yoseikan'), findsOneWidget);
      expect(find.text('Phase 4 of 6'), findsOneWidget);
      expect(find.text('Open phase 4'), findsOneWidget);
      expect(find.text('Prepare the event'), findsOneWidget);
      expect(find.text('New event'), findsOneWidget);
      // Three finished in view, the fourth on demand.
      await tester.scrollUntilVisible(
        find.text('See all 4 finished'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Copa 1'), findsNothing);
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }

  testWidgets('text at 200 % fits my events on a phone', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(tester, _clubEvents);

    await tester.scrollUntilVisible(
      find.text('See all 4 finished'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the phases scroll sideways and each opens its own', (
    tester,
  ) async {
    await pump(tester, _clubEvents);

    // The current phase starts in view; the others are a swipe away.
    expect(find.text('Phase 4'), findsOneWidget);
    await tester.drag(find.text('Phase 4'), const Offset(300, 0));
    await tester.pumpAndSettle();
    await tapText(tester, 'Phase 1');

    expect(find.text('Panel p1'), findsOneWidget);
  });

  testWidgets('the club reaches the whole league from its card', (
    tester,
  ) async {
    await pump(tester, _clubEvents);

    await tapText(tester, 'See the league and its phases');

    expect(find.text('League p4'), findsOneWidget);
  });

  testWidgets('a finished list shows three and the rest on demand', (
    tester,
  ) async {
    await pump(tester, _clubEvents);

    await tapText(tester, 'See all 4 finished');

    expect(find.text('Copa 1'), findsOneWidget);
    expect(find.text('See fewer'), findsOneWidget);
  });

  testWidgets('a helper with several tasks enters the event and picks one', (
    tester,
  ) async {
    await pump(tester, [
      _single(
        'h1',
        'Open de Grappling',
        DateTime(2026, 12, 20),
        PhaseState.inProgress,
        roles: {EventRole.grouper, EventRole.referee},
        permissions: {
          EventPermission.groups,
          EventPermission.control,
          EventPermission.ownMat,
        },
        mat: 2,
      ),
    ], organizer: false);

    expect(find.text('Your tasks'), findsOneWidget);
    expect(find.text('Open my mat 2'), findsOneWidget);
    expect(find.text('New event'), findsNothing);

    await tapText(tester, 'Enter the event');
    expect(find.text('What do you want to open?'), findsOneWidget);
    // The sheet's own entry, over the card's label of the same task.
    await tester.tap(find.text('Make groups').last);
    await tester.pumpAndSettle();

    expect(find.text('Groups h1'), findsOneWidget);
  });

  testWidgets('a helper whose task is not decided sees just that', (
    tester,
  ) async {
    await pump(tester, [
      _single(
        'h2',
        'Trofeo Ciudad de Málaga',
        DateTime(2027, 3, 14),
        PhaseState.notStarted,
        roles: {EventRole.grouper},
        permissions: const {},
      ),
    ], organizer: false);

    expect(find.text('Not decided yet'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.textContaining('Mat'), findsNothing);
  });

  MyEvent referee(PhaseState state) => _single(
    'r1',
    'Open de Grappling',
    DateTime(2026, 12, 20),
    state,
    roles: {EventRole.referee},
    permissions: {EventPermission.ownMat},
    mat: 2,
  );

  testWidgets('a referee mat waits for the phase to start', (tester) async {
    await pump(tester, [referee(PhaseState.notStarted)], organizer: false);

    expect(
      find.text(
        'Your mat opens on December 20, when the club starts the phase.',
      ),
      findsOneWidget,
    );
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('a referee mat on now opens in one tap', (tester) async {
    await pump(tester, [referee(PhaseState.inProgress)], organizer: false);

    await tapText(tester, 'Open my mat 2');

    expect(find.text('Mat m2'), findsOneWidget);
  });

  testWidgets('with no events an organizer is offered to create one', (
    tester,
  ) async {
    await pump(tester, const []);

    expect(find.text('Create your first event'), findsOneWidget);
  });

  testWidgets('with no events a helper is told how events arrive', (
    tester,
  ) async {
    await pump(tester, const [], organizer: false);

    expect(find.text('Create your first event'), findsNothing);
    expect(
      find.textContaining('When a club adds you to a league'),
      findsOneWidget,
    );
  });

  testWidgets('a club event due today says it is today', (tester) async {
    await pump(tester, [
      _single(
        't1',
        'Open de Grappling',
        DateTime(2026, 12, 20),
        PhaseState.notStarted,
      ),
    ], today: DateTime(2026, 12, 20, 9));

    expect(find.textContaining('It is today.'), findsOneWidget);
    expect(find.textContaining('It starts on'), findsNothing);
  });

  testWidgets('a device can show every finished event or none', (tester) async {
    await pump(
      tester,
      _clubEvents,
      prefs: const DevicePrefs(finished: FinishedShown.all),
    );
    await tester.scrollUntilVisible(
      find.text('Copa 1'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('See all'), findsNothing);
  });

  testWidgets('a device that hides the finished events has no such section', (
    tester,
  ) async {
    await pump(
      tester,
      _clubEvents,
      prefs: const DevicePrefs(finished: FinishedShown.none),
    );

    await tester.scrollUntilVisible(
      find.text('Open de Grappling'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Copa 4'), findsNothing);
    expect(find.textContaining('See all'), findsNothing);
  });
}
