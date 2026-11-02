import 'package:brackety_admin/features/organizers/data/organizers_api.dart';
import 'package:brackety_admin/features/organizers/ui/organizer_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  FakeOrganizersApi seeded() => FakeOrganizersApi([
    organizer('club', name: 'Club Deportivo Ejemplo', taxId: 'G12345674'),
    organizer('old', type: OrganizerType.externalEntity),
    organizer('done', name: 'Club Validado', validated: true),
  ]);

  Finder rowOf(String email) =>
      find.ancestor(of: find.text(email), matching: find.byType(OrganizerTile));

  Finder validateIn(Finder row) => find.descendant(
    of: row,
    matching: find.widgetWithText(FilledButton, 'Validate'),
  );

  Future<void> validate(WidgetTester tester, String email) async {
    final button = validateIn(rowOf(email));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  for (final MapEntry(key: device, value: size) in screenSizes.entries) {
    testWidgets('pending organizers show their data on $device', (
      tester,
    ) async {
      useSize(tester, size);
      await pumpAdmin(tester, organizers: seeded(), location: '/organizers');

      expect(find.text('Club Deportivo Ejemplo'), findsOneWidget);
      expect(find.textContaining('G12345674'), findsOneWidget);
      expect(find.text('club@example.test'), findsOneWidget);
      expect(find.textContaining('Oct 30, 2026'), findsNWidgets(2));
      // Created before the sign-up asked for name and CIF.
      expect(find.text('No data'), findsOneWidget);
      expect(find.text('External entity'), findsOneWidget);
      expect(find.text('Club Validado'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('validating asks first and leaves Pending on $device', (
      tester,
    ) async {
      useSize(tester, size);
      await pumpAdmin(tester, organizers: seeded(), location: '/organizers');

      await validate(tester, 'club@example.test');
      expect(find.text('Validate Club Deportivo Ejemplo?'), findsOneWidget);
      expect(find.textContaining('get an email'), findsOneWidget);
      await tapText(tester, 'Validate');

      expect(find.text('club@example.test'), findsNothing);
      expect(find.text('Club Deportivo Ejemplo validated.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('filters switch the list', (tester) async {
    useSize(tester, screenSizes['desktop']!);
    final api = seeded();
    await pumpAdmin(tester, organizers: api, location: '/organizers');

    await tester.tap(find.widgetWithText(ChoiceChip, 'Validated'));
    await tester.pumpAndSettle();
    expect(find.text('Club Validado'), findsOneWidget);
    expect(find.text('club@example.test'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Validate'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();
    expect(find.byType(OrganizerTile), findsNWidgets(3));
    expect(api.queries, [false, true, null]);
  });

  testWidgets('validating in All keeps the row, now validated', (tester) async {
    useSize(tester, screenSizes['phone']!);
    await pumpAdmin(tester, organizers: seeded(), location: '/organizers');
    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();

    await validate(tester, 'old@example.test');
    expect(find.text('Validate old@example.test?'), findsOneWidget);
    await tapText(tester, 'Validate');

    final row = rowOf('old@example.test');
    expect(row, findsOneWidget);
    expect(validateIn(row), findsNothing);
    expect(
      find.descendant(of: row, matching: find.text('Validated')),
      findsOneWidget,
    );
  });

  testWidgets('a gone organizer (404) says so and refreshes', (tester) async {
    useSize(tester, screenSizes['tablet']!);
    final api = seeded()..validateError = dioError(404);
    await pumpAdmin(tester, organizers: api, location: '/organizers');
    api.organizers = [];

    await validate(tester, 'club@example.test');
    await tapText(tester, 'Validate');

    expect(
      find.text(
        'That organizer no longer exists or is no longer an organizer. '
        'List refreshed.',
      ),
      findsOneWidget,
    );
    expect(find.text('No organizers waiting for validation.'), findsOneWidget);
  });
  for (final device in ['phone', 'desktop']) {
    testWidgets('organizers lay out with text at 200 % on $device', (
      tester,
    ) async {
      useSize(tester, screenSizes[device]!);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpAdmin(tester, organizers: seeded(), location: '/organizers');

      expect(find.text('Club Deportivo Ejemplo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
