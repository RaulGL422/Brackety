import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import 'auth_app.dart';

void main() {
  for (final MapEntry(key: device, value: size) in screenSizes.entries) {
    testWidgets('a valid link verifies on $device', (tester) async {
      useSize(tester, size);
      final api = FakeAuthApi();
      await pumpAuthApp(tester, api, location: '/verify-email?token=v1');

      expect(api.verifications, ['v1']);
      expect(find.text('Email verified. Thank you!'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tapText(tester, 'Continue');
      expect(find.text('No account? Sign up'), findsOneWidget);
    });
  }

  testWidgets('signed in, verifying removes the banner', (tester) async {
    final api = FakeAuthApi(signedIn: true)..emailVerified = false;
    final router = await pumpAuthApp(tester, api);
    expect(
      find.text('Verify your email: some actions need it.'),
      findsOneWidget,
    );

    router.go('/verify-email?token=v1');
    await tester.pumpAndSettle();

    expect(find.text('Email verified. Thank you!'), findsOneWidget);
    expect(find.text('Verify your email: some actions need it.'), findsNothing);
  });

  testWidgets('an invalid link signed out points to the sign-in', (
    tester,
  ) async {
    final api = FakeAuthApi()..verifyError = httpError(400);
    await pumpAuthApp(tester, api, location: '/verify-email?token=bad');

    expect(find.text('The link is invalid or has expired.'), findsOneWidget);
    expect(find.text('Go to sign in'), findsOneWidget);
    expect(find.text('Resend email'), findsNothing);
  });

  testWidgets('an invalid link signed in offers to resend', (tester) async {
    final api = FakeAuthApi(signedIn: true)
      ..emailVerified = false
      ..verifyError = httpError(400);
    await pumpAuthApp(tester, api, location: '/verify-email?token=bad');

    expect(find.text('The link is invalid or has expired.'), findsOneWidget);
    // One in the banner, one on the page.
    expect(find.text('Resend email'), findsNWidgets(2));
  });

  testWidgets('without network it offers to retry', (tester) async {
    final api = FakeAuthApi()..verifyError = networkError();
    await pumpAuthApp(tester, api, location: '/verify-email?token=v1');
    expect(find.text('Cannot reach the server.'), findsOneWidget);

    api.verifyError = null;
    await tapText(tester, 'Retry');

    expect(find.text('Email verified. Thank you!'), findsOneWidget);
  });
}
