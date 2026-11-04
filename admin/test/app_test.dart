import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  final serverInfo = serverInfoProvider.overrideWith(
    (ref) async => ServerInfo(name: 'brackety', today: DateTime(2027, 3, 10)),
  );

  for (final MapEntry(key: device, value: size) in screenSizes.entries) {
    testWidgets('signed out, only sign-in and connection open on $device', (
      tester,
    ) async {
      useSize(tester, size);
      final router = await pumpAdmin(
        tester,
        signedIn: false,
        overrides: [serverInfo],
      );

      expect(find.text('Superadmin sign-in'), findsOneWidget);
      router.go('/locks');
      await tester.pumpAndSettle();
      expect(find.text('Superadmin sign-in'), findsOneWidget);

      await tester.tap(find.text('Connection').first);
      await tester.pumpAndSettle();

      expect(find.text(apiBaseUrl), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('signed in, the shell has every section on $device', (
      tester,
    ) async {
      useSize(tester, size);
      await pumpAdmin(tester, overrides: [serverInfo]);

      expect(find.text('Superadmin dashboard'), findsOneWidget);
      for (final label in ['Locks', 'Organizers', 'Connection']) {
        expect(find.text(label), findsWidgets);
      }
      expect(find.byTooltip('Sign out'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('sign out goes back to the sign-in page', (tester) async {
    useSize(tester, screenSizes['desktop']!);
    await pumpAdmin(tester, location: '/locks');

    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Superadmin sign-in'), findsOneWidget);
    expect(find.text('Your session has expired. Sign in again.'), findsNothing);
  });
}
