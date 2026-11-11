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
const _taxId = 'CIF (Spanish tax ID)';
const _declaration = 'I am of legal age and represent this organization.';
const _taxIdHelper =
    'The platform uses it to verify the organization before it can publish events.';

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

  Future<void> fillAccount(WidgetTester tester) async {
    await enterField(tester, 'Email', 'ana@example.com');
    await enterField(tester, 'Password', 'long enough pw');
    await tapAcceptance(tester);
  }

  Future<void> fillHelper(
    WidgetTester tester, {
    required String birthDate,
  }) async {
    await tapText(tester, 'Helper');
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
    await tapText(tester, 'Club');
    await enterField(tester, _orgName, '  Club Yoseikan Sevilla ');
    await enterField(tester, _taxId, taxId);
    if (declare) await tapText(tester, _declaration);
    await fillAccount(tester);
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

    testWidgets('the organizer sign-up fits on $device', (tester) async {
      useSize(tester, size);
      await pumpAuthApp(tester, FakeAuthApi(), location: '/register');

      await tapText(tester, 'Club');

      expect(find.widgetWithText(TextFormField, _orgName), findsOneWidget);
      expect(find.widgetWithText(TextFormField, _taxId), findsOneWidget);
      expect(find.text(_taxIdHelper), findsOneWidget);
      expect(find.text(_declaration), findsOneWidget);
      expect(find.text('Date of birth'), findsNothing);
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

  testWidgets('dev offers every profile, and an external entity is an '
      'organizer', (tester) async {
    await pumpAuthApp(
      tester,
      FakeAuthApi(),
      location: '/register',
      devEnvironment: true,
    );

    expect(find.byType(RadioListTile<ProfileType>), findsNWidgets(5));
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('External'), findsOneWidget);

    await tapText(tester, 'External entity');
    expect(find.widgetWithText(TextFormField, _taxId), findsOneWidget);
    expect(find.text('Date of birth'), findsNothing);
  });

  testWidgets('the profile comes first and decides the fields', (tester) async {
    await pumpAuthApp(tester, FakeAuthApi(), location: '/register');

    expect(find.text('Date of birth'), findsNothing);
    expect(find.widgetWithText(TextFormField, _taxId), findsNothing);
    expect(
      tester.getTopLeft(find.text('How will you use Brackety?')).dy,
      lessThan(tester.getTopLeft(find.text('Email')).dy),
    );

    await tapText(tester, 'Helper');
    expect(find.text('Date of birth'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, _taxId), findsNothing);
  });

  testWidgets('switching profile keeps what was typed', (tester) async {
    await pumpAuthApp(tester, FakeAuthApi(), location: '/register');

    await tapText(tester, 'Club');
    await enterField(tester, _orgName, 'Club Yoseikan Sevilla');
    await tapText(tester, _declaration);
    await enterField(tester, 'Email', 'ana@example.com');
    await tapText(tester, 'Helper');
    await tapText(tester, 'Club');

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

    await tapText(tester, 'Create account');

    expect(find.text('Required.'), findsOneWidget);
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

    await fillHelper(tester, birthDate: '11/01/2012');
    await tapText(tester, 'Create account');

    expect(find.textContaining('adding a minor profile'), findsOneWidget);
    expect(api.registrations, isEmpty);
  });

  testWidgets('a club sends its organization and the declaration, no birth '
      'date', (tester) async {
    final api = FakeAuthApi();
    await pumpAuthApp(tester, api, location: '/register');

    await fillClub(tester);
    await tapText(tester, 'Create account');

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
    await tapText(tester, 'Create account');

    final json = api.registrations.single.toJson();
    expect(json['birthDate'], '1990-05-07');
    expect(json.containsKey('organization'), isFalse);
    expect(json.containsKey('representativeDeclaration'), isFalse);
  });

  testWidgets('an organizer must declare they represent it', (tester) async {
    final api = FakeAuthApi();
    await pumpAuthApp(tester, api, location: '/register');

    await fillClub(tester, declare: false);
    await tapText(tester, 'Create account');

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
    await tapText(tester, 'Create account');

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
    await tapText(tester, 'Create account');

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

    await fillHelper(tester, birthDate: '05/07/1990');
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

      await fillHelper(tester, birthDate: '05/07/1990');
      await tapText(tester, 'Create account');

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
    await tapText(tester, 'Create account');

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
    await tapText(tester, 'Create account');
    expect(find.byType(FormMessage), findsOneWidget);
    expect(api.registrations, isEmpty);

    legal.versionsError = null;
    await tapText(tester, 'Create account');
    expect(api.registrations, hasLength(1));
  });

  for (final (link, title) in [
    ('terms of use', 'Terms of use'),
    ('privacy policy', 'Privacy policy'),
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

      expect(find.widgetWithText(AppBar, title), findsOneWidget);
      expect(legal.texts.last.$2, 'en');

      await tester.tap(find.byIcon(Icons.chevron_left));
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
    await tapText(tester, 'Create account');

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
    await tapText(tester, 'Create account');

    final json = api.registrations.single.toJson();
    expect(json['acceptedTermsVersion'], '2026-12-01');
    expect(json['acceptedPrivacyVersion'], '2026-12-01');
  });
}
