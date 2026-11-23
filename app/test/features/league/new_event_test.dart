import 'package:brackety/features/events/state/events_providers.dart';
import 'package:brackety/features/events/ui/events_screen.dart';
import 'package:brackety/features/league/data/league_models.dart';
import 'package:brackety/features/league/data/league_repository.dart';
import 'package:brackety/l10n/gen/app_localizations.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Creates a standalone event and says what it was asked.
class _FakeLeagueRepository extends Fake implements LeagueRepository {
  final created = <(String, String, int)>[];

  @override
  Future<List<Sport>> sports() async => const [
    Sport(
      code: 'TAMBO',
      names: {'es': 'Tambo', 'en': 'Tambo'},
      available: true,
    ),
    Sport(
      code: 'GRAPPLING',
      names: {'es': 'Grappling', 'en': 'Grappling'},
      available: true,
    ),
    Sport(
      code: 'GROUND',
      names: {'es': 'Suelo', 'en': 'Ground'},
      available: false,
    ),
  ];

  @override
  Future<LeaguePhase> createEvent({
    required String name,
    required DateTime date,
    required String sport,
    required int mats,
  }) async {
    created.add((name, sport, mats));
    return LeaguePhase.fromJson({
      'eventId': 'new',
      'number': 1,
      'name': name,
      'date': '2027-05-08',
      'discipline': 'GRAPPLING',
      'participants': 0,
    });
  }
}

void main() {
  const sizes = {
    'phone': Size(360, 800),
    'tablet': Size(800, 1280),
    'desktop': Size(1440, 900),
  };

  Future<_FakeLeagueRepository> open(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = _FakeLeagueRepository();
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const EventsScreen()),
        GoRoute(
          path: '/events/:id/club',
          builder: (_, state) =>
              Scaffold(body: Text('Panel ${state.pathParameters['id']}')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          leagueRepositoryProvider.overrideWithValue(repository),
          myEventsProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (_, child) => ToastHost(child: child!),
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
    return repository;
  }

  for (final MapEntry(key: device, value: size) in sizes.entries) {
    testWidgets(
      'an account creates a grappling event and lands in its panel on $device',
      (tester) async {
        final repository = await open(tester, size);

        await tester.tap(find.text('New event'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Event name'),
          'Open de grappling',
        );
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        // The names come from each sport's template; one without a scoreboard is listed for later.
        expect(find.text('Ground (coming soon)'), findsWidgets);
        await tester.tap(find.text('Grappling').last);
        await tester.pumpAndSettle();
        await tester.enterText(find.widgetWithText(TextFormField, 'Mats'), '3');
        await tester.tap(find.text('Create event'));
        await tester.pumpAndSettle();

        expect(repository.created.single, (
          'Open de grappling',
          'GRAPPLING',
          3,
        ));
        expect(find.text('Panel new'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('the sport and the mats are checked before anything is sent', (
    tester,
  ) async {
    final repository = await open(tester, sizes['phone']!);

    await tester.tap(find.text('New event'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Event name'),
      'Open',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Mats'), '0');
    await tester.tap(find.text('Create event'));
    await tester.pumpAndSettle();

    // No sport picked.
    expect(find.text('Required.'), findsOneWidget);
    expect(find.text('From 1 to 20'), findsOneWidget);
    expect(repository.created, isEmpty);
  });
}
