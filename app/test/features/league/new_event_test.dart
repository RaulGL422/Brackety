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
  final created = <(String, Discipline, int)>[];

  @override
  Future<Set<Discipline>> disciplines() async => {
    Discipline.tambo,
    Discipline.grappling,
  };

  @override
  Future<LeaguePhase> createEvent({
    required String name,
    required DateTime date,
    required Discipline discipline,
    required int mats,
  }) async {
    created.add((name, discipline, mats));
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
        await tester.tap(find.byType(DropdownButtonFormField<Discipline>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Grappling').last);
        await tester.pumpAndSettle();
        await tester.enterText(find.widgetWithText(TextFormField, 'Mats'), '3');
        await tester.tap(find.text('Create event'));
        await tester.pumpAndSettle();

        expect(repository.created.single, (
          'Open de grappling',
          Discipline.grappling,
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
