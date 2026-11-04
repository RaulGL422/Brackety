import 'package:brackety_admin/features/auth/data/admin_api_error.dart';
import 'package:brackety_admin/features/auth/ui/admin_texts.dart';
import 'package:brackety_admin/l10n/gen/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  String login(DioException error) =>
      loginErrorMessage(l10n, AdminApiError.from(error));

  test('401 at sign-in is the generic wrong credentials', () {
    expect(login(dioError(401)), l10n.loginInvalid);
  });

  test('429 with a lock id is the admin lock, without it the limiter', () {
    final locked = AdminApiError.from(
      dioError(429, data: {'lockId': 'L-7K2F'}),
    );
    expect(locked.isLocked, isTrue);
    expect(
      login(dioError(429, data: {'lockId': 'L-7K2F'})),
      contains('L-7K2F'),
    );

    final limited = dioError(
      429,
      headers: {
        'retry-after': ['30'],
      },
    );
    expect(AdminApiError.from(limited).isRateLimited, isTrue);
    expect(login(limited), l10n.tooManyRequests(30));
    expect(login(dioError(429)), l10n.tooManyRequestsWait);
  });

  test('503 is "not configured" and 403 is the Cloudflare Access refusal', () {
    expect(login(dioError(503)), l10n.adminNotConfigured);
    expect(login(dioError(403)), l10n.adminAccessDenied);
  });

  test('no answer, and anything else', () {
    expect(login(networkError()), l10n.noServer);
    expect(login(dioError(500)), l10n.unexpectedError);
  });

  test('a failed action says nothing on 401: the sign-in page explains', () {
    expect(actionErrorMessage(l10n, AdminApiError.from(dioError(401))), isNull);
    expect(
      actionErrorMessage(l10n, AdminApiError.from(dioError(503))),
      l10n.adminNotConfigured,
    );
  });
}
