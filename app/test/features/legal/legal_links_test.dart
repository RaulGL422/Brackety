import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../auth/auth_app.dart';

const _footer = ['Privacy', 'Terms', 'Cookies', 'Legal notice', 'Licenses'];

void main() {
  for (final location in ['/login', '/register']) {
    testWidgets('$location has the legal footer', (tester) async {
      await pumpAuthApp(tester, FakeAuthApi(), location: location);

      for (final label in _footer) {
        expect(find.widgetWithText(TextButton, label), findsOneWidget);
      }
    });
  }

  for (final MapEntry(key: device, value: size) in screenSizes.entries) {
    testWidgets('the footer fits and opens a page and back on $device', (
      tester,
    ) async {
      useSize(tester, size);
      await pumpAuthApp(tester, FakeAuthApi());

      await tapText(tester, 'Cookies');
      expect(find.widgetWithText(AppBar, 'Cookie policy'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('No account? Sign up'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('"Licenses" opens the software licenses', (tester) async {
    await pumpAuthApp(tester, FakeAuthApi());

    await tapText(tester, 'Licenses');

    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('the settings list the legal documents and the licenses', (
    tester,
  ) async {
    await pumpAuthApp(
      tester,
      FakeAuthApi(signedIn: true),
      location: '/settings',
    );
    await tester.scrollUntilVisible(
      find.widgetWithText(ListTile, 'Software licenses'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    for (final title in [
      'Privacy policy',
      'Terms of use',
      'Cookie policy',
      'Legal notice',
      'Software licenses',
    ]) {
      expect(find.widgetWithText(ListTile, title), findsOneWidget);
    }

    await tapText(tester, 'Terms of use');
    expect(find.text('terms (en)'), findsOneWidget);
  });
}
