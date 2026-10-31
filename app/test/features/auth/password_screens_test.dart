import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import 'auth_app.dart';

void main() {
  group('forgot password', () {
    for (final MapEntry(key: device, value: size) in screenSizes.entries) {
      testWidgets('fits on $device', (tester) async {
        useSize(tester, size);
        await pumpAuthApp(tester, FakeAuthApi(), location: '/forgot-password');

        expect(find.text('Send link'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('always answers with the same neutral message', (tester) async {
      final api = FakeAuthApi();
      await pumpAuthApp(tester, api);
      await tapText(tester, 'Forgot your password?');

      await tester.enterText(find.byType(TextField), 'ana@example.com');
      await tapText(tester, 'Send link');

      expect(api.forgotten, ['ana@example.com']);
      expect(
        find.text(
          'If there is an account with that email, we have sent you a link to change the password.',
        ),
        findsOneWidget,
      );
    });
  });

  group('reset password', () {
    Future<void> enterPasswords(
      WidgetTester tester,
      String password,
      String confirmation,
    ) async {
      await tester.enterText(find.byType(TextField).at(0), password);
      await tester.enterText(find.byType(TextField).at(1), confirmation);
      await tapText(tester, 'Change password');
    }

    for (final MapEntry(key: device, value: size) in screenSizes.entries) {
      testWidgets('fits on $device', (tester) async {
        useSize(tester, size);
        await pumpAuthApp(
          tester,
          FakeAuthApi(),
          location: '/reset-password?token=t1',
        );

        expect(find.text('Repeat the password'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the passwords must match', (tester) async {
      final api = FakeAuthApi();
      await pumpAuthApp(tester, api, location: '/reset-password?token=t1');

      await enterPasswords(tester, 'long enough pw', 'something else');

      expect(find.text('The passwords do not match.'), findsOneWidget);
      expect(api.resets, isEmpty);
    });

    testWidgets('a reset leads to the sign-in with a message, even signed in', (
      tester,
    ) async {
      final api = FakeAuthApi(signedIn: true);
      await pumpAuthApp(tester, api, location: '/reset-password?token=t1');

      await enterPasswords(tester, 'long enough pw', 'long enough pw');

      expect(api.resets, ['t1']);
      expect(
        find.text('Password changed. You can sign in with the new one.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    });

    testWidgets('an expired link offers a new one', (tester) async {
      final api = FakeAuthApi()..resetError = httpError(400);
      await pumpAuthApp(tester, api, location: '/reset-password?token=old');

      await enterPasswords(tester, 'long enough pw', 'long enough pw');
      expect(find.text('The link is invalid or has expired.'), findsOneWidget);

      await tapText(tester, 'Request another link');
      expect(find.text('Send link'), findsOneWidget);
    });

    testWidgets('a link without token is invalid at once', (tester) async {
      await pumpAuthApp(tester, FakeAuthApi(), location: '/reset-password');

      expect(find.text('The link is invalid or has expired.'), findsOneWidget);
    });
  });
}
