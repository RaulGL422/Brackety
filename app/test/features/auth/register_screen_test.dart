import 'package:brackety/features/auth/data/registration.dart';
import 'package:brackety/features/auth/ui/widgets/form_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import 'auth_app.dart';

void main() {
  Future<void> fillForm(
    WidgetTester tester, {
    required String birthDate,
  }) async {
    await tester.enterText(find.byType(TextField).at(0), 'ana@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'long enough pw');
    await tapText(tester, 'Date of birth');
    await tester.enterText(
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.byType(TextField),
      ),
      birthDate,
    );
    await tapText(tester, 'OK');
    await tapText(tester, 'Helper');
    await tapText(tester, 'I accept the terms of use and the privacy policy.');
  }

  for (final MapEntry(key: device, value: size) in screenSizes.entries) {
    testWidgets('the sign-up fits on $device', (tester) async {
      useSize(tester, size);
      await pumpAuthApp(tester, FakeAuthApi(), location: '/register');

      expect(find.text('How will you use Brackety?'), findsOneWidget);
      expect(
        find.text('Helps at events: groups, table or refereeing.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('only Club and Helper are offered outside dev', (tester) async {
    await pumpAuthApp(tester, FakeAuthApi(), location: '/register');

    expect(find.byType(RadioListTile<ProfileType>), findsNWidgets(2));
    expect(find.text('Club'), findsOneWidget);
    expect(find.text('Helper'), findsOneWidget);
    expect(find.text('Student'), findsNothing);
    expect(find.text('External'), findsNothing);
    expect(find.text('External entity'), findsNothing);
  });

  testWidgets('dev offers every profile', (tester) async {
    await pumpAuthApp(
      tester,
      FakeAuthApi(),
      location: '/register',
      devEnvironment: true,
    );

    expect(find.byType(RadioListTile<ProfileType>), findsNWidgets(5));
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('External'), findsOneWidget);
    expect(find.text('External entity'), findsOneWidget);
  });

  testWidgets('an empty form says what is missing', (tester) async {
    final api = FakeAuthApi();
    await pumpAuthApp(tester, api, location: '/register');

    await tapText(tester, 'Create account');

    expect(find.text('Required.'), findsNWidgets(2));
    expect(
      find.text('The password needs at least 10 characters.'),
      findsOneWidget,
    );
    expect(find.text('Choose a profile.'), findsOneWidget);
    expect(
      find.text('You must accept them to create the account.'),
      findsOneWidget,
    );
    expect(api.registrations, isEmpty);
  });

  testWidgets('under 14 cannot sign up alone', (tester) async {
    final api = FakeAuthApi();
    await pumpAuthApp(tester, api, location: '/register');

    await fillForm(tester, birthDate: '11/01/2012');
    await tapText(tester, 'Create account');

    expect(find.textContaining('adding a minor profile'), findsOneWidget);
    expect(api.registrations, isEmpty);
  });

  testWidgets('a new account is signed in at once and sees the banner', (
    tester,
  ) async {
    final api = FakeAuthApi()..emailVerified = false;
    await pumpAuthApp(tester, api, location: '/register');

    await fillForm(tester, birthDate: '05/07/1990');
    await tapText(tester, 'Create account');

    expect(api.logins, ['ana@example.com']);
    expect(find.text('My events'), findsOneWidget);
    expect(
      find.text('Verify your email: some actions need it.'),
      findsOneWidget,
    );
  });

  testWidgets('an email that already had an account gets the neutral '
      '"check your email", which can resend', (tester) async {
    final api = FakeAuthApi();
    api.accounts['ana@example.com'] = 'another password';
    await pumpAuthApp(tester, api, location: '/register');

    await fillForm(tester, birthDate: '05/07/1990');
    await tapText(tester, 'Create account');

    final registration = api.registrations.single;
    expect(registration.email, 'ana@example.com');
    expect(registration.birthDate, DateTime(1990, 5, 7));
    expect(registration.profile, ProfileType.helper);
    expect(registration.locale, 'en');
    expect(api.logins, isEmpty);
    expect(find.text('Check your email'), findsOneWidget);
    expect(find.byType(FormMessage), findsNothing);

    await tapText(tester, 'Resend email');
    expect(api.resends, ['ana@example.com']);
    expect(find.text('Email sent.'), findsOneWidget);

    await tapText(tester, 'Go to sign in');
    expect(find.text('No account? Sign up'), findsOneWidget);
  });

  testWidgets('the sign-in links to the sign-up and back', (tester) async {
    await pumpAuthApp(tester, FakeAuthApi());

    await tapText(tester, 'No account? Sign up');
    expect(find.text('How will you use Brackety?'), findsOneWidget);

    await tapText(tester, 'Already have an account? Sign in');
    expect(find.text('No account? Sign up'), findsOneWidget);
  });

  for (final (name, error) in [
    ('a lock', httpError(429, body: {'lockId': 'L-7K2F'})),
    ('no network', networkError()),
  ]) {
    testWidgets('a sign-in failing with $name after signing up still says '
        '"check your email"', (tester) async {
      final api = FakeAuthApi()..loginError = error;
      await pumpAuthApp(tester, api, location: '/register');

      await fillForm(tester, birthDate: '05/07/1990');
      await tapText(tester, 'Create account');

      expect(api.registrations, hasLength(1));
      expect(find.text('Check your email'), findsOneWidget);
      expect(find.textContaining('L-7K2F'), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    });
  }
}
