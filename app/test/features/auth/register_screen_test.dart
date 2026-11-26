import 'package:brackety/features/auth/data/registration.dart';
import 'package:brackety/features/auth/ui/widgets/form_message.dart';
import 'package:brackety/features/legal/data/legal_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/legal_fakes.dart';
import 'auth_app.dart';

const _accept = 'I accept the terms of use and the privacy policy.';
const _orgName = 'Organization name';
const _clubName = 'Club name';
const _taxId = 'CIF (Spanish tax ID)';
const _declaration = 'I am of legal age and represent this club.';
const _taxIdHelper = 'We check it before it can publish events.';

void main() {
  Future<void> enterField(
    WidgetTester tester,
    String label,
    String text,
  ) async {
    final field = find.widgetWithText(TextFormField, label);
    await tester.ensureVisible(field);
    await tester.enterText(field, text);
    await tester.pumpAndSettle();
  }

  // Its middle is a link: the box itself is tapped.
  Future<void> tapAcceptance(WidgetTester tester) async {
    final box = find.descendant(
      of: find.widgetWithText(CheckboxListTile, _accept),
      matching: find.byType(Checkbox),
    );
    await tester.ensureVisible(box);
    await tester.tap(box);
    await tester.pumpAndSettle();
  }

  bool accepted(WidgetTester tester) => tester
      .widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, _accept))
      .value!;

  Future<void> chooseProfile(WidgetTester tester, String name) async {
    final dropdown = find.byType(DropdownButtonFormField<ProfileType>);
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  Future<void> fillAccount(WidgetTester tester) async {
    await enterField(tester, 'Email', 'ana@example.com');
    await enterField(tester, 'Password', 'long enough pw');
    await tapAcceptance(tester);
  }

  Future<void> fillHelper(
    WidgetTester tester, {
    required String birthDate,
  }) async {
    await chooseProfile(tester, 'Helper');
    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.byType(TextField),
      ),
      birthDate,
    );
    await tapText(tester, 'OK');
    await fillAccount(tester);
  }

  Future<void> fillClub(
    WidgetTester tester, {
    String taxId = 'b-1234567 4',
    bool declare = true,
  }) async {
    await chooseProfile(tester, 'Club');
    await enterField(tester, _clubName, '  Club Yoseikan Sevilla ');
    await enterField(tester, _taxId, taxId);
    if (declare) await tapText(tester, _declaration);
    await fillAccount(tester);
  }

  for (final MapEntry(key: device, value: size) in screenSizes.entries) {
    testWidgets('the sign-up fits on $device', (tester) async {
      useSize(tester, size);
      await pumpAuthApp(tester, FakeAuthApi(), location: '/register');
      await chooseProfile(tester, 'Helper');

      expect(find.text('Account type'), findsOneWidget);
      expect(find.text('About you'), findsOneWidget);
      expect(
        find.text('Helps at events: groups, table or refereeing.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the organizer sign-up fits on $device', (tester) async {
      useSize(tester, size);
      await pumpAuthApp(tester, FakeAuthApi(), location: '/register');

      await chooseProfile(tester, 'Club');

      expect(find.text('Your club'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, _clubName), findsOneWidget);
      expect(find.widgetWithText(TextFormField, _taxId), findsOneWidget);
      expect(find.text(_taxIdHelper), findsOneWidget);
      expect(find.text(_declaration), findsOneWidget);
      expect(find.text('Date of birth'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('only Club and Helper are offered outside dev', (tester) async {
    await pumpAuthApp(tester, FakeAuthApi(), location: '/register');

    await tester.tap(find.byType(DropdownButtonFormField<ProfileType>));
    await tester.pumpAndSettle();

    expect(find.text('Club'), findsWidgets);
    expect(find.text('Helper'), findsWidgets);
    expect(find.text('Student'), findsNothing);
    expect(find.text('External'), findsNothing);
    expect(find.text('External entity'), findsNothing);
  });

  testWidgets('dev offers every profile, and an external entity is an '
      'organizer', (tester) async {
    await pumpAuthApp(
      tester,
      FakeAuthApi(),
      location: '/register',
      devEnvironment: true,
    );

    await tester.tap(find.byType(DropdownButtonFormField<ProfileType>));
    await tester.pumpAndSettle();
    expect(find.text('Student'), findsWidgets);
    expect(find.text('External'), findsWidgets);
    await tester.tap(find.text('External entity').last);
    await tester.pumpAndSettle();

    expect(find.text('Your organization'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, _orgName), findsOneWidget);
    expect(find.widgetWithText(TextFormField, _taxId), findsOneWidget);
    expect(find.text('Date of birth'), findsNothing);
  });

  testWidgets('the profile comes first and decides the fields', (tester) async {
    await pumpAuthApp(tester, FakeAuthApi(), location: '/register');

    expect(find.text('Date of birth'), findsNothing);
    expect(find.widgetWithText(TextFormField, _taxId), findsNothing);
    expect(
      tester.getTopLeft(find.text('Account type')).dy,
      lessThan(tester.getTopLeft(find.text('Email')).dy),
    );

    await chooseProfile(tester, 'Helper');
    expect(find.text('Date of birth'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, _taxId), findsNothing);
  });

  testWidgets('switching profile keeps what was typed', (tester) async {
    await pumpAuthApp(tester, FakeAuthApi(), location: '/register');

    await chooseProfile(tester, 'Club');
    await enterField(tester, _clubName, 'Club Yoseikan Sevilla');
    await tapText(tester, _declaration);
    await enterField(tester, 'Email', 'ana@example.com');
    await chooseProfile(tester, 'Helper');
    await chooseProfile(tester, 'Club');

    expect(find.text('Club Yoseikan Sevilla'), findsOneWidget);
    expect(find.text('ana@example.com'), findsOneWidget);
    final declaration = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, _declaration),
    );
    expect(declaration.value, isTrue);
  });

  testWidgets('an empty form says what is missing', (tester) async {
    final api = FakeAuthApi();
    await pumpAuthApp(tester, api, location: '/register');

    await tapText(tester, 'Create the account');

    expect(
      find.text('4 things left to check. We took you to the first.'),
      findsOneWidget,
    );
    expect(find.text('Required.'), findsOneWidget);
    expect(
      find.text('The password needs at least 10 characters.'),
      findsOneWidget,
    );
    expect(find.text('Choose the account type.'), findsOneWidget);
    expect(find.text('Tick the box to create the account.'), findsOneWidget);
    expect(api.registrations, isEmpty);
  });

  testWidgets('an email without its ending says what is missing', (
    tester,
  ) async {
    await pumpAuthApp(tester, FakeAuthApi(), location: '/register');

    await enterField(tester, 'Email', 'ana@example');
    await tapText(tester, 'Create the account');

    expect(
      find.text('The end of the email is missing, like “.com”.'),
      findsOneWidget,
    );
  });

  testWidgets('the password says how far it is from long enough', (
    tester,
  ) async {
    await pumpAuthApp(tester, FakeAuthApi(), location: '/register');

    expect(find.text('At least 10 characters'), findsOneWidget);
    await enterField(tester, 'Password', 'short');
    expect(find.text('At least 10 characters (5 so far)'), findsOneWidget);
  });

  testWidgets('under 14 cannot sign up alone', (tester) async {
    final api = FakeAuthApi();
    await pumpAuthApp(tester, api, location: '/register');

    await fillHelper(tester, birthDate: '11/01/2012');
    await tapText(tester, 'Create the account');

    expect(find.textContaining('adding a minor profile'), findsOneWidget);
    expect(api.registrations, isEmpty);
  });

  testWidgets('a club sends its organization and the declaration, no birth '
      'date', (tester) async {
    final api = FakeAuthApi();
    await pumpAuthApp(tester, api, location: '/register');

    await fillClub(tester);
    await tapText(tester, 'Create the account');

    final registration = api.registrations.single;
    expect(registration.profile, ProfileType.club);
    final json = registration.toJson();
    expect(json['organization'], {
      'name': 'Club Yoseikan Sevilla',
      'taxId': 'B12345674',
    });
    expect(json['representativeDeclaration'], isTrue);
    expect(json.containsKey('birthDate'), isFalse);
  });

  testWidgets('a helper sends the birth date and no organization', (
    tester,
  ) async {
    final api = FakeAuthApi();
    await pumpAuthApp(tester, api, location: '/register');

    await fillHelper(tester, birthDate: '05/07/1990');
    await tapText(tester, 'Create the account');

    final json = api.registrations.single.toJson();
    expect(json['birthDate'], '1990-05-07');
    expect(json.containsKey('organization'), isFalse);
    expect(json.containsKey('representativeDeclaration'), isFalse);
  });

  testWidgets('an organizer must declare they represent it', (tester) async {
    final api = FakeAuthApi();
    await pumpAuthApp(tester, api, location: '/register');

    await fillClub(tester, declare: false);
    await tapText(tester, 'Create the account');

    expect(
      find.text('You must confirm it to register the organization.'),
      findsOneWidget,
    );
    expect(api.registrations, isEmpty);
  });

  testWidgets('a wrong CIF is caught before sending', (tester) async {
    final api = FakeAuthApi();
    await pumpAuthApp(tester, api, location: '/register');

    await fillClub(tester, taxId: 'B12345675');
    await tapText(tester, 'Create the account');

    expect(find.text('Invalid CIF.'), findsOneWidget);
    expect(api.registrations, isEmpty);
  });

  testWidgets('a CIF the server rejects is shown on its field until edited', (
    tester,
  ) async {
    final api = FakeAuthApi()
      ..registerError = httpError(400, body: {'code': 'INVALID_TAX_ID'});
    await pumpAuthApp(tester, api, location: '/register');

    await fillClub(tester);
    await tapText(tester, 'Create the account');

    expect(
      find.descendant(
        of: find.widgetWithText(TextFormField, _taxId),
        matching: find.text('Invalid CIF.'),
      ),
      findsOneWidget,
    );
    expect(find.byType(FormMessage), findsNothing);

    await enterField(tester, _taxId, 'G12345674');
    expect(find.text('Invalid CIF.'), findsNothing);
  });

  testWidgets('a new account is signed in at once and sees the banner', (
    tester,
  ) async {
    final api = FakeAuthApi()..emailVerified = false;
    await pumpAuthApp(tester, api, location: '/register');

    await fillHelper(tester, birthDate: '05/07/1990');
    await tapText(tester, 'Create the account');

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

    await fillHelper(tester, birthDate: '05/07/1990');
    await tapText(tester, 'Create the account');

    final registration = api.registrations.single;
    expect(registration.email, 'ana@example.com');
    expect(registration.birthDate, DateTime(1990, 5, 7));
    expect(registration.profile, ProfileType.helper);
    expect(registration.locale, 'en');
    expect(api.logins, isEmpty);
    expect(find.text('Check your email'), findsOneWidget);
    expect(find.byType(FormMessage), findsNothing);

    await tapText(tester, 'Resend the email');
    expect(api.resends, ['ana@example.com']);
    expect(find.text('Email sent.'), findsOneWidget);

    await tapText(tester, 'Sign in');
    expect(find.text('Create an account'), findsOneWidget);
  });

  testWidgets('the sign-in links to the sign-up and back', (tester) async {
    await pumpAuthApp(tester, FakeAuthApi());

    await tapText(tester, 'Create an account');
    expect(find.text('Account type'), findsOneWidget);

    await tapText(tester, 'Sign in');
    expect(find.text('Create an account'), findsOneWidget);
  });

  for (final (name, error) in [
    ('a lock', httpError(429, body: {'lockId': 'L-7K2F'})),
    ('no network', networkError()),
  ]) {
    testWidgets('a sign-in failing with $name after signing up still says '
        '"check your email"', (tester) async {
      final api = FakeAuthApi()..loginError = error;
      await pumpAuthApp(tester, api, location: '/register');

      await fillHelper(tester, birthDate: '05/07/1990');
      await tapText(tester, 'Create the account');

      expect(api.registrations, hasLength(1));
      expect(find.text('Check your email'), findsOneWidget);
      expect(find.textContaining('L-7K2F'), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    });
  }

  testWidgets('sends the versions the server has when the form opens', (
    tester,
  ) async {
    final api = FakeAuthApi();
    final legal = FakeLegalRepository(
      versionsAnswer: const LegalVersions(terms: 't-7', privacy: 'p-3'),
    );
    await pumpAuthApp(tester, api, location: '/register', legal: legal);
    expect(legal.versionsCalls, 1);

    await fillHelper(tester, birthDate: '05/07/1990');
    await tapText(tester, 'Create the account');

    final json = api.registrations.single.toJson();
    expect(json['acceptedTermsVersion'], 't-7');
    expect(json['acceptedPrivacyVersion'], 'p-3');
  });

  testWidgets('without the versions the sign-up says there is no server and '
      'tries again on the next submit', (tester) async {
    final api = FakeAuthApi();
    final legal = FakeLegalRepository()..versionsError = networkError();
    await pumpAuthApp(tester, api, location: '/register', legal: legal);

    await fillHelper(tester, birthDate: '05/07/1990');
    await tapText(tester, 'Create the account');
    expect(find.byType(FormMessage), findsOneWidget);
    expect(api.registrations, isEmpty);

    legal.versionsError = null;
    await tapText(tester, 'Create the account');
    expect(api.registrations, hasLength(1));
  });

  for (final (link, slug) in [
    ('terms of use', 'terms'),
    ('privacy policy', 'privacy'),
  ]) {
    testWidgets('"$link" opens its page and the form is kept on the way back', (
      tester,
    ) async {
      final legal = FakeLegalRepository();
      await pumpAuthApp(
        tester,
        FakeAuthApi(),
        location: '/register',
        legal: legal,
      );
      await enterField(tester, 'Email', 'ana@example.com');

      final text = find.textRange.ofSubstring(link);
      await tester.ensureVisible(find.text(_accept));
      await tester.tapOnText(text);
      await tester.pumpAndSettle();

      // The page names itself in its heading (the fake text's own title), not in the bar.
      expect(find.text('$slug (en)'), findsOneWidget);
      expect(legal.texts.last.$2, 'en');

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('ana@example.com'), findsOneWidget);
      expect(accepted(tester), isFalse);
    });
  }

  testWidgets('outdated versions untick the box, ask to accept again and the '
      'next submit sends the new ones', (tester) async {
    final api = FakeAuthApi()
      ..registerError = httpError(
        409,
        body: {'code': 'LEGAL_VERSION_OUTDATED'},
      );
    final legal = FakeLegalRepository();
    await pumpAuthApp(tester, api, location: '/register', legal: legal);

    await fillHelper(tester, birthDate: '05/07/1990');
    legal.versionsAnswer = const LegalVersions(
      terms: '2026-12-01',
      privacy: '2026-12-01',
    );
    await tapText(tester, 'Create the account');

    expect(
      find.text(
        'The terms of use or the privacy policy have changed. Review them '
        'and accept them again.',
      ),
      findsOneWidget,
    );
    expect(accepted(tester), isFalse);
    expect(legal.versionsCalls, 2);

    api.registerError = null;
    await tapAcceptance(tester);
    await tapText(tester, 'Create the account');

    final json = api.registrations.single.toJson();
    expect(json['acceptedTermsVersion'], '2026-12-01');
    expect(json['acceptedPrivacyVersion'], '2026-12-01');
  });
}
