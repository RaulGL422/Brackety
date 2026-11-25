import 'package:brackety/features/auth/data/account.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import 'auth_app.dart';

// The terms or the privacy policy changed since the account accepted them (docs/modulos/legal-paginas.md).
void main() {
  const terms = PendingConsent(document: 'terms', version: '2026-12-01');

  Future<FakeAccountApi> pumpPending(WidgetTester tester, {String? at}) async {
    final account = FakeAccountApi(
      account: testAccount(pendingConsents: const [terms]),
    );
    await pumpAuthApp(
      tester,
      FakeAuthApi(signedIn: true),
      account: account,
      location: at,
    );
    return account;
  }

  for (final MapEntry(key: device, value: size) in screenSizes.entries) {
    testWidgets('a changed text keeps the account on its screen on $device', (
      tester,
    ) async {
      useSize(tester, size);
      final handle = tester.ensureSemantics();
      await pumpPending(tester, at: '/settings');

      expect(find.text('A legal text has changed'), findsOneWidget);
      expect(find.text('Version of December 1, 2026'), findsOneWidget);
      expect(find.text('Privacy policy'), findsNothing);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  }

  testWidgets('accepting asks for the box and then goes where it was going', (
    tester,
  ) async {
    final account = await pumpPending(tester, at: '/settings');

    await tapText(tester, 'Accept and continue');
    expect(account.acceptedConsents, isEmpty);

    await tester.tap(find.byType(Checkbox));
    await tapText(tester, 'Accept and continue');

    expect(account.acceptedConsents.single.single.version, '2026-12-01');
    expect(find.text('A legal text has changed'), findsNothing);
  });

  testWidgets('the text can be read from there and back', (tester) async {
    await pumpPending(tester);

    await tester.tap(find.text('Terms of use'));
    await tester.pumpAndSettle();
    expect(find.text('A legal text has changed'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('A legal text has changed'), findsOneWidget);
  });

  // Raul, 2026-11-25: the box names the texts, an opened one says so, and signing out is the
  // other way out, apart.
  testWidgets('the box names the texts and an opened one is marked', (
    tester,
  ) async {
    await pumpPending(tester);

    expect(
      find.text('I have read and accept the terms of use.'),
      findsOneWidget,
    );
    expect(find.text('Already read'), findsNothing);
    expect(find.text("Don't agree?"), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Sign out'), findsOneWidget);

    await tester.tap(find.text('Terms of use'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Already read'), findsOneWidget);
  });

  testWidgets('two changed texts are counted and both named', (tester) async {
    await pumpAuthApp(
      tester,
      FakeAuthApi(signedIn: true),
      account: FakeAccountApi(
        account: testAccount(
          pendingConsents: const [
            PendingConsent(document: 'privacy', version: '2026-12-01'),
            terms,
          ],
        ),
      ),
    );

    expect(find.text('2 legal texts have changed'), findsOneWidget);
    expect(
      find.text(
        'I have read and accept the privacy policy and the terms of use.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a text changed again while reading says so', (tester) async {
    (await pumpPending(tester)).consentError = httpError(
      409,
      body: {'code': 'LEGAL_VERSION_OUTDATED'},
    );

    await tester.tap(find.byType(Checkbox));
    await tapText(tester, 'Accept and continue');

    expect(find.textContaining('changed again'), findsOneWidget);
  });

  testWidgets('text at 200 % fits on a phone', (tester) async {
    useSize(tester, const Size(360, 800));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpPending(tester);

    expect(find.text('A legal text has changed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('without anything pending the app opens as always', (
    tester,
  ) async {
    await pumpAuthApp(
      tester,
      FakeAuthApi(signedIn: true),
      account: FakeAccountApi(),
      location: '/settings',
    );

    expect(find.text('A legal text has changed'), findsNothing);
  });
}
