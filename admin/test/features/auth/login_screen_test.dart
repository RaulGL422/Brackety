import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  Future<void> signIn(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'superadmin@example.test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'brackety-demo',
    );
    await tapText(tester, 'Sign in');
  }

  for (final MapEntry(key: device, value: size) in screenSizes.entries) {
    testWidgets('sign-in opens the dashboard on $device', (tester) async {
      useSize(tester, size);
      final auth = FakeAdminAuthApi();
      await pumpAdmin(tester, signedIn: false, auth: auth);

      await signIn(tester);

      expect(auth.logins.single, ('superadmin@example.test', 'brackety-demo'));
      expect(find.text('Superadmin dashboard'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a wrong password says so on $device', (tester) async {
      useSize(tester, size);
      final auth = FakeAdminAuthApi()..error = dioError(401);
      await pumpAdmin(tester, signedIn: false, auth: auth);

      await signIn(tester);

      expect(find.text('Wrong email or password.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('empty fields are required', (tester) async {
    useSize(tester, screenSizes['phone']!);
    final auth = FakeAdminAuthApi();
    await pumpAdmin(tester, signedIn: false, auth: auth);

    await tapText(tester, 'Sign in');

    expect(find.text('Required field'), findsNWidgets(2));
    expect(auth.logins, isEmpty);
  });

  testWidgets('the admin lock shows its id', (tester) async {
    useSize(tester, screenSizes['phone']!);
    final auth = FakeAdminAuthApi()
      ..error = dioError(429, data: {'lockId': 'L-7K2F'});
    await pumpAdmin(tester, signedIn: false, auth: auth);

    await signIn(tester);

    expect(find.textContaining('L-7K2F'), findsOneWidget);
  });

  testWidgets('a server without superadmin says it is not configured', (
    tester,
  ) async {
    useSize(tester, screenSizes['phone']!);
    final auth = FakeAdminAuthApi()..error = dioError(503);
    await pumpAdmin(tester, signedIn: false, auth: auth);

    await signIn(tester);

    expect(
      find.text('Superadmin access is not configured on this server.'),
      findsOneWidget,
    );
  });

  for (final MapEntry(key: device, value: size) in screenSizes.entries) {
    testWidgets('an expired session goes back to sign-in on $device', (
      tester,
    ) async {
      useSize(tester, size);
      final adapter = FakeAdapter((_) => (401, null));
      await pumpAdmin(
        tester,
        realApis: true,
        overrides: [dioProvider.overrideWithValue(fakeDio(adapter))],
      );

      await tester.tap(find.text('Locks').first);
      await tester.pumpAndSettle();

      expect(find.text('Superadmin sign-in'), findsOneWidget);
      expect(
        find.text('Your session has expired. Sign in again.'),
        findsOneWidget,
      );
      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer admin-token',
      );
      expect(tester.takeException(), isNull);
    });
  }
}
