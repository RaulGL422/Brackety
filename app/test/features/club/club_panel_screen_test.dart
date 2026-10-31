import 'package:brackety/features/club/data/club_models.dart';
import 'package:brackety/features/club/state/club_providers.dart';
import 'package:brackety/features/club/ui/club_panel_screen.dart';
import 'package:brackety/features/club/ui/participant_form.dart';
import 'package:brackety/features/events/data/my_event.dart';
import 'package:brackety/features/events/state/events_providers.dart';
import 'package:brackety/l10n/gen/app_localizations.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  Future<void> pumpPanel(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myEventsProvider.overrideWith((ref) async => [event]),
          eventSettingsProvider.overrideWith((ref, _) async => settings),
          standingsProvider.overrideWith((ref, _) async => standings),
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

      await tester.tap(find.text('The legal guardian agrees'));
      await tester.pump();
      expect(save().onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    });
  }

  test('age counts whole years up to the day before the birthday', () {
    final birth = DateTime(2019, 11, 14);
    expect(ageOn(birth, DateTime(2026, 11, 13)), 6);
    expect(ageOn(birth, DateTime(2026, 11, 14)), 7);
    expect(ageOn(DateTime(2008, 12, 1), DateTime(2026, 11, 14)), 17);
  });
}
