import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../auth/auth_app.dart';

void main() {
  for (final MapEntry(key: device, value: size) in screenSizes.entries) {
    testWidgets(
      'scanning the QR signs in with no account of one\'s own on $device',
      (tester) async {
        useSize(tester, size);
        final api = FakeAuthApi();
        final router = await pumpAuthApp(tester, api, location: '/qr?code=c1');

        expect(api.qrCodes, ['c1']);
        expect(router.routeInformationProvider.value.uri.path, '/');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('a used or renewed QR says to ask the club for a new one', (
    tester,
  ) async {
    final api = FakeAuthApi()..qrError = httpError(400);
    await pumpAuthApp(tester, api, location: '/qr?code=old');

    expect(
      find.text('This QR no longer works: ask the club for a new one.'),
      findsOneWidget,
    );
    expect(find.text('Go to sign in'), findsOneWidget);
  });

  testWidgets('signed in with another account, it asks before replacing it', (
    tester,
  ) async {
    final api = FakeAuthApi(signedIn: true);
    await pumpAuthApp(tester, api, location: '/qr?code=c1');

    expect(api.qrCodes, isEmpty);
    expect(find.textContaining('will end'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(api.qrCodes, ['c1']);
    expect(api.logouts, hasLength(1));
  });
}
