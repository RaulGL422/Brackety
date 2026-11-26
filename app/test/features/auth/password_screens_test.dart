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

        expect(find.text('Send the link'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('always answers with the same neutral message', (tester) async {
      final api = FakeAuthApi();
      await pumpAuthApp(tester, api);
      await tapText(tester, 'Forgot your password?');

      await tester.enterText(find.byType(TextField), 'ana@example.com');
      await tapText(tester, 'Send the link');

      expect(api.forgotten, ['ana@example.com']);
      expect(
        find.text(
          'If there is an account with ana@example.com, it now has an email with the link. '
          'It expires in 1 hour.',
        ),
        findsOneWidget,
      );

      await tapText(tester, 'Try another email');
      expect(find.text('Send the link'), findsOneWidget);
      expect(find.text('ana@example.com'), findsNothing);
    });

    testWidgets('tells a QR account to ask the club instead', (tester) async {
      await pumpAuthApp(tester, FakeAuthApi(), location: '/forgot-password');

      expect(
        find.text(
          'Do you sign in with the username the club gave you? Ask the club for a new QR.',
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
      await tapText(tester, 'Save the password');
    }

    for (final MapEntry(key: device, value: size) in screenSizes.entries) {
      testWidgets('fits on $device', (tester) async {
        useSize(tester, size);
        await pumpAuthApp(
          tester,
          FakeAuthApi(),
          location: '/reset-password?token=t1',
        );

        expect(find.text('Repeat it'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the rules tick as the passwords are typed', (tester) async {
      await pumpAuthApp(
        tester,
        FakeAuthApi(),
        location: '/reset-password?token=t1',
      );

      expect(find.text('At least 10 characters'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), 'short');
      await tester.pump();
      expect(find.text('At least 10 characters (5 so far)'), findsOneWidget);
      expect(find.text('They match'), findsNothing);

      await tester.enterText(find.byType(TextField).at(0), 'long enough pw');
      await tester.enterText(find.byType(TextField).at(1), 'long enough pw');
      await tester.pump();
      expect(find.text('At least 10 characters'), findsOneWidget);
      expect(find.text('They match'), findsOneWidget);
    });

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
      expect(find.text('This link no longer works'), findsOneWidget);
      expect(
        find.text(
          'Links to change the password expire in 1 hour and work only once.',
        ),
        findsOneWidget,
      );

      await tapText(tester, 'Request another link');
      expect(find.text('Send the link'), findsOneWidget);
    });

    testWidgets('a valid link is checked on open and shows the form', (
      tester,
    ) async {
      final api = FakeAuthApi();
      await pumpAuthApp(tester, api, location: '/reset-password?token=t1');

      expect(api.resetChecks, ['t1']);
      expect(find.text('Repeat it'), findsOneWidget);
    });

    testWidgets('an invalid link is told on open', (tester) async {
      final api = FakeAuthApi()..resetCheckError = httpError(400);
      await pumpAuthApp(tester, api, location: '/reset-password?token=old');

      expect(
        find.text(
          'Links to change the password expire in 1 hour and work only once.',
        ),
        findsOneWidget,
      );
      expect(find.text('Repeat it'), findsNothing);
      expect(find.text('Request another link'), findsOneWidget);
    });

    testWidgets('without network the form shows anyway', (tester) async {
      final api = FakeAuthApi()..resetCheckError = networkError();
      await pumpAuthApp(tester, api, location: '/reset-password?token=t1');

      expect(find.text('Repeat it'), findsOneWidget);
    });

    testWidgets('a link without token is invalid at once', (tester) async {
      await pumpAuthApp(tester, FakeAuthApi(), location: '/reset-password');

      expect(
        find.text(
          'Links to change the password expire in 1 hour and work only once.',
        ),
        findsOneWidget,
      );
    });
  });
}
