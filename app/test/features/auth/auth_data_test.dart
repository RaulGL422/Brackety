import 'package:brackety/features/auth/data/api_error.dart';
import 'package:brackety/features/auth/data/registration.dart';
import 'package:brackety/features/auth/data/tax_id.dart';
import 'package:brackety/features/auth/ui/auth_texts.dart';
import 'package:brackety/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  group('ApiError', () {
    test('a 429 with lockId is an account lock', () {
      final error = ApiError.from(httpError(429, body: {'lockId': 'L-7K2F'}));

      expect(error.isLocked, isTrue);
      expect(error.isRateLimited, isFalse);
      expect(error.lockId, 'L-7K2F');
    });

    test('a 429 without lockId is the rate limiter, with its wait', () {
      final error = ApiError.from(
        httpError(
          429,
          headers: {
            'Retry-After': ['42'],
          },
        ),
      );

      expect(error.isRateLimited, isTrue);
      expect(error.isLocked, isFalse);
      expect(error.retryAfter, const Duration(seconds: 42));
    });

    test('a pending deletion brings its date and restore token', () {
      final error = ApiError.from(
        httpError(
          403,
          body: {
            'code': 'ACCOUNT_PENDING_DELETION',
            'deletesOn': '2026-11-30',
            'restoreToken': 'r-token',
          },
        ),
      );

      expect(error.isPendingDeletion, isTrue);
      expect(error.deletesOn, DateTime(2026, 11, 30));
      expect(error.restoreToken, 'r-token');
    });

    test('another 403 code is not a pending deletion', () {
      final error = ApiError.from(
        httpError(403, body: {'code': 'REAUTH_REQUIRED'}),
      );

      expect(error.isPendingDeletion, isFalse);
      expect(error.code, 'REAUTH_REQUIRED');
    });

    test('no answer from the server has no status', () {
      final error = ApiError.from(networkError());

      expect(error.noResponse, isTrue);
      expect(error.isLocked, isFalse);
    });
  });

  group('registration', () {
    final today = DateTime(2026, 10, 31);

    test('14 is old enough from the birthday itself', () {
      expect(isOldEnoughToRegister(DateTime(2012, 10, 31), today), isTrue);
      expect(isOldEnoughToRegister(DateTime(2012, 11, 1), today), isFalse);
      expect(isOldEnoughToRegister(DateTime(1980, 1, 1), today), isTrue);
    });

    test('sends the provisional legal version and the server field names', () {
      final json = Registration(
        email: 'ana@example.com',
        password: 'long enough',
        birthDate: DateTime(1990, 5, 7),
        profile: ProfileType.helper,
        locale: 'es',
      ).toJson();

      expect(json, {
        'email': 'ana@example.com',
        'password': 'long enough',
        'birthDate': '1990-05-07',
        'profile': 'HELPER',
        'acceptedTermsVersion': '2026-11-draft',
        'acceptedPrivacyVersion': '2026-11-draft',
        'locale': 'es',
      });
    });

    test('an organizer sends the organization and the declaration, and no '
        'birth date key', () {
      final json = const Registration(
        email: 'club@example.com',
        password: 'long enough',
        profile: ProfileType.externalEntity,
        locale: 'es',
        organization: Organization(name: 'Federación', taxId: 'G12345674'),
        representativeDeclaration: true,
      ).toJson();

      expect(json, {
        'email': 'club@example.com',
        'password': 'long enough',
        'profile': 'EXTERNAL_ENTITY',
        'organization': {'name': 'Federación', 'taxId': 'G12345674'},
        'representativeDeclaration': true,
        'acceptedTermsVersion': '2026-11-draft',
        'acceptedPrivacyVersion': '2026-11-draft',
        'locale': 'es',
      });
    });

    test('only clubs and external entities are organizers', () {
      expect(ProfileType.values.where((profile) => profile.isOrganizer), [
        ProfileType.club,
        ProfileType.externalEntity,
      ]);
    });
  });

  group('CIF', () {
    test('accepts the known valid ones', () {
      expect(isValidCif('B12345674'), isTrue);
      expect(isValidCif('G12345674'), isTrue);
      expect(isValidCif('G1234567D'), isTrue);
    });

    test('normalizes case, spaces, hyphens and dots first', () {
      expect(normalizeTaxId('b-1234567 4'), 'B12345674');
      expect(normalizeTaxId('g.123.456.7d'), 'G1234567D');
      expect(isValidCif('b-1234567 4'), isTrue);
    });

    test('rejects a wrong length or shape', () {
      expect(isValidCif(''), isFalse);
      expect(isValidCif('B1234567'), isFalse);
      expect(isValidCif('B123456745'), isFalse);
      expect(isValidCif('1B2345674'), isFalse);
      expect(isValidCif('B12A45674'), isFalse);
    });

    test('rejects a first letter that is not a CIF type', () {
      for (final letter in ['I', 'K', 'L', 'M', 'O', 'T', 'X', 'Y', 'Z']) {
        expect(isValidCif('${letter}12345674'), isFalse, reason: letter);
      }
    });

    test('rejects a wrong control', () {
      expect(isValidCif('B12345675'), isFalse);
      expect(isValidCif('G1234567E'), isFalse);
    });

    test('P, Q, R, S, N and W need the control letter', () {
      for (final letter in ['P', 'Q', 'R', 'S', 'N', 'W']) {
        expect(isValidCif('${letter}1234567D'), isTrue, reason: letter);
        expect(isValidCif('${letter}12345674'), isFalse, reason: letter);
      }
    });

    test('A, B, E and H need the control digit', () {
      for (final letter in ['A', 'B', 'E', 'H']) {
        expect(isValidCif('${letter}12345674'), isTrue, reason: letter);
        expect(isValidCif('${letter}1234567D'), isFalse, reason: letter);
      }
    });

    test('the other letters take either', () {
      for (final letter in ['C', 'D', 'F', 'G', 'J', 'U', 'V']) {
        expect(isValidCif('${letter}12345674'), isTrue, reason: letter);
        expect(isValidCif('${letter}1234567D'), isTrue, reason: letter);
      }
    });
  });

  group('organizer field validation', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    test('the organization name is trimmed and 2 to 200 long', () {
      expect(validateOrganizationName(l10n, '   '), l10n.fieldRequired);
      expect(
        validateOrganizationName(l10n, ' A '),
        l10n.registerOrganizationNameLength,
      );
      expect(validateOrganizationName(l10n, ' AB '), isNull);
      expect(validateOrganizationName(l10n, 'A' * 200), isNull);
      expect(
        validateOrganizationName(l10n, 'A' * 201),
        l10n.registerOrganizationNameLength,
      );
    });

    test('the CIF is required and checked', () {
      expect(validateTaxId(l10n, ' - '), l10n.fieldRequired);
      expect(validateTaxId(l10n, 'B12345675'), l10n.registerTaxIdInvalid);
      expect(validateTaxId(l10n, 'b-1234567 4'), isNull);
    });
  });

  group('rate limiter message', () {
    final limited = ApiError.from(
      httpError(
        429,
        headers: {
          'Retry-After': ['17'],
        },
      ),
    );

    test('uses the seconds from Retry-After', () {
      expect(
        apiErrorMessage(lookupAppLocalizations(const Locale('es')), limited),
        'Demasiadas peticiones. Espera 17 s y vuelve a intentarlo.',
      );
      expect(
        apiErrorMessage(lookupAppLocalizations(const Locale('en')), limited),
        'Too many requests. Wait 17 s and try again.',
      );
    });

    test('without Retry-After asks to wait a moment', () {
      expect(
        apiErrorMessage(
          lookupAppLocalizations(const Locale('en')),
          ApiError.from(httpError(429)),
        ),
        'Too many requests. Wait a moment and try again.',
      );
    });
  });
}
