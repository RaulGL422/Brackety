import 'dart:ui';

import 'package:brackety/core/error_codes.dart';
import 'package:brackety/l10n/gen/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('es'));

  DioException refusal(Object? body) {
    final options = RequestOptions(path: '/x');
    return DioException(
      requestOptions: options,
      response: Response(requestOptions: options, statusCode: 409, data: body),
    );
  }

  test('a known code says the refusal in the user language', () {
    expect(
      errorMessage(l10n, refusal({'code': 'DATE_LOCKED'}), 'generic'),
      l10n.errorDateLocked,
    );
  });

  test('an unknown code, no code or no body fall back to the screen text', () {
    expect(
      errorMessage(l10n, refusal({'code': 'NEW_IN_A_LATER_SERVER'}), 'generic'),
      'generic',
    );
    expect(errorMessage(l10n, refusal({'detail': 'x'}), 'generic'), 'generic');
    expect(errorMessage(l10n, refusal('not json'), 'generic'), 'generic');
    expect(errorMessage(l10n, refusal(null), 'generic'), 'generic');
  });
}
