import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  for (final MapEntry(key: device, value: size) in screenSizes.entries) {
    testWidgets('every count shows and fits on $device', (tester) async {
      useSize(tester, size);
      await pumpAdmin(tester);

      expect(find.text('Superadmin dashboard'), findsOneWidget);
      for (final (label, value) in [
        ('Active accounts', '12'),
        ('Organizers to validate', '3'),
        ('Helpers', '2'),
        ('Entries', '75'),
        ('Imported in 7 days', '40'),
        ('Scoreboard actions in 24 h', '240'),
        ('Matches in progress now', '3'),
        ('API 5xx errors', '0'),
      ]) {
        await tester.scrollUntilVisible(
          find.text(label),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        final tile = find.ancestor(
          of: find.text(label),
          matching: find.byType(Card),
        );
        expect(
          find.descendant(of: tile, matching: find.text(value)),
          findsOneWidget,
          reason: label,
        );
      }
      // Nothing to look at: no state icons.
      expect(find.byIcon(Icons.warning_amber), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('matches in review and server errors say so with an icon', (
    tester,
  ) async {
    useSize(tester, screenSizes['desktop']!);
    await pumpAdmin(
      tester,
      metrics: FakeMetricsApi(metrics(inReview: 2, serverErrors: 4)),
    );

    expect(find.text('The club has to review them'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Check the API logs'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('refresh reads them again', (tester) async {
    useSize(tester, screenSizes['desktop']!);
    final api = FakeMetricsApi();
    await pumpAdmin(tester, metrics: api);
    expect(api.reads, 1);

    api.value = metrics(inReview: 1);
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();

    expect(api.reads, 2);
    expect(find.text('The club has to review them'), findsOneWidget);
  });
}
