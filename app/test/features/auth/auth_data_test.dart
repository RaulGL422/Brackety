import 'package:brackety/features/auth/data/api_error.dart';
import 'package:brackety/features/auth/data/registration.dart';
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
        profile: ProfileType.externalEntity,
        locale: 'es',
      ).toJson();

      expect(json, {
        'email': 'ana@example.com',
        'password': 'long enough',
        'birthDate': '1990-05-07',
        'profile': 'EXTERNAL_ENTITY',
        'acceptedTermsVersion': '2026-11-draft',
        'acceptedPrivacyVersion': '2026-11-draft',
        'locale': 'es',
      });
    });
  });
}
