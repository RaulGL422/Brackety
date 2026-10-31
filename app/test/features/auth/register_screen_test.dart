import 'package:brackety/features/auth/data/registration.dart';
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
        find.text('Follows events and results without belonging to a club.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

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

    expect(find.textContaining('Children under 14'), findsOneWidget);
    expect(api.registrations, isEmpty);
  });

  testWidgets('signing up leads to "check your email", which can resend', (
    tester,
  ) async {
    final api = FakeAuthApi();
    await pumpAuthApp(tester, api, location: '/register');

    await fillForm(tester, birthDate: '05/07/1990');
    await tapText(tester, 'Create account');

    final registration = api.registrations.single;
    expect(registration.email, 'ana@example.com');
    expect(registration.birthDate, DateTime(1990, 5, 7));
    expect(registration.profile, ProfileType.helper);
    expect(registration.locale, 'en');
    expect(find.text('Check your email'), findsOneWidget);

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
}
