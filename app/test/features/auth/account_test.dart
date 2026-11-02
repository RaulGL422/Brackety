import 'dart:ui';

import 'package:brackety/features/auth/data/account.dart';
import 'package:brackety/features/auth/data/registration.dart';
import 'package:brackety/features/auth/state/account_controller.dart';
import 'package:brackety/features/auth/state/reauth.dart';
import 'package:brackety/features/auth/ui/settings/account_action.dart';
import 'package:brackety/l10n/gen/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  group('reauth', () {
    late FakeAccountApi api;
    late DateTime now;
    late Reauth reauth;
    late int asked;

    setUp(() {
      api = FakeAccountApi();
      now = DateTime(2026, 11, 2, 10);
      reauth = Reauth(api, now: () => now);
      asked = 0;
    });

    Future<bool> prove() async {
      asked++;
      await reauth.confirmPassword(api.password);
      return true;
    }

    Future<String> echo(String token) async => token;

    test('asks the password once while the token lives', () async {
      expect(await reauth.run(echo, prove), 'reauth-1');
      now = now.add(const Duration(minutes: 4));
      expect(await reauth.run(echo, prove), 'reauth-1');

      expect(asked, 1);
      expect(api.reauths, [api.password]);
    });

    test('asks again once the token is about to expire', () async {
      await reauth.run(echo, prove);
      now = now.add(const Duration(minutes: 4, seconds: 50));

      expect(await reauth.run(echo, prove), 'reauth-2');
      expect(asked, 2);
    });

    test('on REAUTH_REQUIRED asks again and repeats the action once', () async {
      await reauth.run(echo, prove);
      final tokens = <String>[];

      final result = await reauth.run((token) async {
        tokens.add(token);
        if (tokens.length == 1) {
          throw httpError(403, body: {'code': 'REAUTH_REQUIRED'});
        }
        return 'done';
      }, prove);

      expect(result, 'done');
      expect(tokens, ['reauth-1', 'reauth-2']);
      expect(asked, 2);
    });

    test('a second REAUTH_REQUIRED is not retried', () async {
      var calls = 0;

      await expectLater(
        reauth.run((token) async {
          calls++;
          throw httpError(403, body: {'code': 'REAUTH_REQUIRED'});
        }, prove),
        throwsA(isA<DioException>()),
      );
      expect(calls, 2);
    });

    test('other failures are not retried', () async {
      var calls = 0;

      await expectLater(
        reauth.run((token) async {
          calls++;
          throw httpError(409, body: {'code': 'OWNS_EVENTS'});
        }, prove),
        throwsA(isA<DioException>()),
      );
      expect(calls, 1);
      expect(asked, 1);
    });

    test('cancelling the dialog does not run the action', () async {
      var ran = false;

      await expectLater(
        reauth.run((token) async => ran = true, () async => false),
        throwsA(isA<ReauthCancelled>()),
      );
      expect(ran, isFalse);
    });

    test('a wrong password keeps no token', () async {
      await expectLater(
        reauth.confirmPassword('wrong'),
        throwsA(isA<DioException>()),
      );

      await expectLater(
        reauth.run(echo, () async => true),
        throwsA(isA<ReauthCancelled>()),
      );
    });
  });

  group('messages', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    test('wrong password and lock in the reauth', () {
      expect(
        accountErrorMessage(l10n, httpError(429, body: {'lockId': 'L-7K2F'})),
        contains('L-7K2F'),
      );
      expect(accountErrorMessage(l10n, const ReauthCancelled()), isNull);
      expect(
        accountErrorMessage(l10n, const ReauthNeedsGoogle()),
        l10n.needsGoogle,
      );
    });

    test('the conflicts of each action', () {
      String? message(int status, [String? code]) => accountErrorMessage(
        l10n,
        httpError(status, body: code == null ? null : {'code': code}),
      );

      expect(message(409, 'LAST_PROFILE'), l10n.profileLast);
      expect(
        message(409, 'PROFILE_COMBINATION_NOT_ALLOWED'),
        l10n.profileCombination,
      );
      expect(message(409, 'OWNS_EVENTS'), l10n.deleteOwnsEvents);
      expect(message(409, 'LAST_SIGN_IN_METHOD'), l10n.lastSignInMethod);
      expect(message(403), l10n.profileNeedsVerifiedEmail);
      expect(accountErrorMessage(l10n, networkError()), l10n.noServer);
    });
  });

  group('app language', () {
    Future<Locale?> localeWith({
      required bool signedIn,
      String locale = 'es',
    }) async {
      final container = ProviderContainer(
        overrides: sessionOverrides(
          FakeAuthApi(signedIn: signedIn),
          account: FakeAccountApi(account: testAccount(locale: locale)),
        ),
      );
      addTearDown(container.dispose);
      final listener = container.listen(appLocaleProvider, (_, _) {});
      await container.read(accountProvider.future);
      // The session restores itself first; then the account loads.
      await pumpEventQueue();
      await container.read(accountProvider.future);
      return listener.read();
    }

    test('signed in, the account language', () async {
      expect(await localeWith(signedIn: true), const Locale('es'));
      expect(
        await localeWith(signedIn: true, locale: 'en'),
        const Locale('en'),
      );
    });

    test('signed out or unsupported, the device language', () async {
      expect(await localeWith(signedIn: false), isNull);
      expect(await localeWith(signedIn: true, locale: 'fr'), isNull);
    });
  });

  test('the export is named after its UTC day', () {
    expect(
      exportFileName(DateTime.utc(2026, 11, 2, 23, 30)),
      'brackety-data-2026-11-02.json',
    );
    expect(
      exportFileName(DateTime.utc(2027, 1, 5)),
      'brackety-data-2027-01-05.json',
    );
  });

  group('profiles to add', () {
    Account withProfiles(List<ProfileType> types) => testAccount(
      profiles: [for (final type in types) AccountProfile(type: type)],
    );

    test('outside dev only Helper, and never an organizer', () {
      expect(
        addableProfiles(
          withProfiles([ProfileType.student]),
          devEnvironment: false,
        ),
        [ProfileType.helper],
      );
      expect(
        addableProfiles(
          withProfiles([ProfileType.helper]),
          devEnvironment: false,
        ),
        isEmpty,
      );
    });

    test('in dev also Student and External', () {
      expect(
        addableProfiles(
          withProfiles([ProfileType.helper]),
          devEnvironment: true,
        ),
        [ProfileType.external, ProfileType.student],
      );
    });

    test('an organizer gets nothing to add', () {
      expect(
        addableProfiles(withProfiles([ProfileType.club]), devEnvironment: true),
        isEmpty,
      );
    });
  });

  test('/me with an organizer and a profile this app does not know', () {
    final account = Account.fromJson({
      'email': 'club@example.com',
      'emailVerified': true,
      'birthDate': null,
      'locale': 'es',
      'profiles': [
        {
          'type': 'CLUB',
          'validated': false,
          'organizationName': 'Club Yoseikan Sevilla',
          'taxId': 'G41234567',
        },
        {'type': 'REFEREE', 'validated': false},
      ],
      'signInMethods': [
        {'method': 'PASSWORD'},
        {
          'method': 'GOOGLE',
          'email': 'club@gmail.com',
          'linkedAt': '2026-10-01T10:00:00Z',
        },
      ],
    });

    expect(account.profiles.single.type, ProfileType.club);
    expect(account.profiles.single.organizationName, 'Club Yoseikan Sevilla');
    expect(account.hasPassword, isTrue);
    expect(account.google?.email, 'club@gmail.com');
  });
}
