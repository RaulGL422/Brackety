import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import 'auth_app.dart';

void main() {
  Future<void> signIn(
    WidgetTester tester,
    String email,
    String password,
  ) async {
    await tester.enterText(find.byType(TextField).at(0), email);
    await tester.enterText(find.byType(TextField).at(1), password);
    await tapText(tester, 'Sign in');
  }

  for (final MapEntry(key: device, value: size) in screenSizes.entries) {
    testWidgets('the sign-in fits and shows its links on $device', (
      tester,
    ) async {
      useSize(tester, size);
      final handle = tester.ensureSemantics();
      await pumpAuthApp(tester, FakeAuthApi());

      expect(find.text('Forgot your password?'), findsOneWidget);
      expect(find.text('Create an account'), findsOneWidget);
      expect(find.text('Test accounts (development only)'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }

  // Raul, 2026-11-25: no app bar; the name above, the title as the screen's heading, the legal
  // texts and the app's version apart at the foot.
  testWidgets('the sign-in has its heading, the legal texts and the version', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpAuthApp(tester, FakeAuthApi());

    expect(find.byType(AppBar), findsNothing);
    expect(find.text('BRACKETY'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Sign in').first),
      matchesSemantics(label: 'Sign in', isHeader: true),
    );
    for (final link in ['Privacy', 'Terms', 'Cookies', 'Legal notice']) {
      expect(find.text(link), findsOneWidget);
    }
    expect(find.text('Software licenses'), findsOneWidget);
    handle.dispose();
  });

  // Raul, 2026-11-25: what failed shows as a notice under the heading, as in the design, not a
  // line lost below the fields.
  testWidgets('a failed sign-in shows its notice above the fields', (
    tester,
  ) async {
    final api = FakeAuthApi()..loginError = networkError();
    await pumpAuthApp(tester, api);

    await signIn(tester, 'ana@example.com', 'whatever123');

    expect(
      tester.getBottomLeft(find.text('Cannot reach the server.')).dy,
      lessThan(tester.getTopLeft(find.byType(TextField).first).dy),
    );
  });

  testWidgets('text at 200 % fits the sign-in on a phone', (tester) async {
    useSize(tester, screenSizes['phone']!);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpAuthApp(tester, FakeAuthApi());

    await tester.scrollUntilVisible(
      find.text('Software licenses'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });

  // GR-2: a referee let in by QR whose session dropped got an empty sign-in screen.
  testWidgets('a lost QR session brings its sign-in back', (tester) async {
    final store = FakeRefreshTokenStore(inCookie: true)..qrSignIn = 'qr-k3f9a2';
    await pumpAuthApp(tester, FakeAuthApi(), store: store);

    expect(find.text('Your session closed'), findsOneWidget);
    expect(find.text('qr-k3f9a2'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Forgot your password?'), findsNothing);
    expect(find.text('Create an account'), findsNothing);
  });

  testWidgets('the QR referee signs in with the password alone', (
    tester,
  ) async {
    final api = FakeAuthApi()..accounts['qr-k3f9a2'] = 'club-pass';
    final store = FakeRefreshTokenStore(inCookie: true)..qrSignIn = 'qr-k3f9a2';
    await pumpAuthApp(tester, api, store: store);

    await tester.enterText(find.byType(TextField), 'club-pass');
    await tapText(tester, 'Sign in');

    expect(api.logins, ['qr-k3f9a2']);
  });

  testWidgets('another account gets the full sign-in back', (tester) async {
    final store = FakeRefreshTokenStore(inCookie: true)..qrSignIn = 'qr-k3f9a2';
    await pumpAuthApp(tester, FakeAuthApi(), store: store);

    await tapText(tester, 'Sign in with another account');

    expect(find.text('Your session closed'), findsNothing);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Forgot your password?'), findsOneWidget);
  });

  testWidgets('without a QR account used here nothing is offered', (
    tester,
  ) async {
    await pumpAuthApp(
      tester,
      FakeAuthApi(),
      store: FakeRefreshTokenStore(inCookie: true),
    );

    expect(find.textContaining('the club gave you'), findsNothing);
    expect(find.widgetWithText(TextField, 'qr-k3f9a2'), findsNothing);
  });

  testWidgets('empty fields are not sent', (tester) async {
    final api = FakeAuthApi();
    await pumpAuthApp(tester, api);

    await tapText(tester, 'Sign in');

    expect(find.text('Required.'), findsNWidgets(2));
    expect(api.logins, isEmpty);
  });

  testWidgets('a locked account shows its lock id', (tester) async {
    final api = FakeAuthApi()
      ..loginError = httpError(429, body: {'lockId': 'L-7K2F'});
    await pumpAuthApp(tester, api);

    await signIn(tester, 'ana@example.com', 'whatever123');

    expect(find.textContaining('L-7K2F'), findsOneWidget);
    expect(find.textContaining('15 minutes'), findsOneWidget);
  });

  testWidgets('a suspended account is told so', (tester) async {
    final api = FakeAuthApi()
      ..loginError = httpError(403, body: {'code': 'ACCOUNT_SUSPENDED'});
    await pumpAuthApp(tester, api);

    await signIn(tester, 'ana@example.com', 'whatever123');

    expect(find.textContaining('This account is suspended'), findsOneWidget);
  });

  testWidgets('the rate limiter says how long to wait', (tester) async {
    final api = FakeAuthApi()
      ..loginError = httpError(
        429,
        headers: {
          'Retry-After': ['30'],
        },
      );
    await pumpAuthApp(tester, api);

    await signIn(tester, 'ana@example.com', 'whatever123');

    expect(
      find.text('Too many requests. Wait 30 s and try again.'),
      findsOneWidget,
    );
  });

  testWidgets('no network says so', (tester) async {
    final api = FakeAuthApi()..loginError = networkError();
    await pumpAuthApp(tester, api);

    await signIn(tester, 'ana@example.com', 'whatever123');

    expect(find.text('Cannot reach the server.'), findsOneWidget);
  });

  testWidgets('an account pending deletion can be restored from the dialog', (
    tester,
  ) async {
    final api = FakeAuthApi()
      ..loginError = httpError(
        403,
        body: {
          'code': 'ACCOUNT_PENDING_DELETION',
          'deletesOn': '2026-11-30',
          'restoreToken': 'r-token',
        },
      );
    await pumpAuthApp(tester, api);

    await signIn(tester, 'ana@example.com', 'whatever123');

    expect(find.text('Account pending deletion'), findsOneWidget);
    expect(
      find.text(
        'Your account will be deleted on November 30, 2026. Do you want to restore it?',
      ),
      findsOneWidget,
    );

    await tapText(tester, 'Restore account');

    expect(api.restores, ['r-token']);
    expect(find.text('My events'), findsOneWidget);
  });

  testWidgets('cancelling the restore stays on the sign-in', (tester) async {
    final api = FakeAuthApi()
      ..loginError = httpError(
        403,
        body: {
          'code': 'ACCOUNT_PENDING_DELETION',
          'deletesOn': '2026-11-30',
          'restoreToken': 'r-token',
        },
      );
    await pumpAuthApp(tester, api);

    await signIn(tester, 'ana@example.com', 'whatever123');
    await tapText(tester, 'Cancel');

    expect(api.restores, isEmpty);
    expect(find.text('Create an account'), findsOneWidget);
  });

  // Raul, 2026-11-26: as in the design, the way to sign up is a compact button beside its question,
  // not a second full-width button competing with «Sign in».
  testWidgets('«Create an account» is a compact button beside its question', (
    tester,
  ) async {
    useSize(tester, screenSizes['desktop']!);
    await pumpAuthApp(tester, FakeAuthApi());

    final button = find.widgetWithText(OutlinedButton, 'Create an account');
    final question = find.text('No account yet?');
    final signIn = find.widgetWithText(FilledButton, 'Sign in');
    // The test font is wide: here the two do not fit on one row, so the button goes under.
    final sameRow =
        (tester.getCenter(button).dy - tester.getCenter(question).dy).abs() < 1;
    expect(
      sameRow
          ? tester.getTopLeft(button).dx > tester.getTopRight(question).dx
          : tester.getTopLeft(button).dy >= tester.getBottomLeft(question).dy,
      isTrue,
    );
    expect(
      tester.getSize(button).width,
      lessThan(tester.getSize(signIn).width * 0.8),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the password can be shown', (tester) async {
    await pumpAuthApp(tester, FakeAuthApi());
    TextField password() =>
        tester.widget<TextField>(find.byType(TextField).at(1));

    expect(password().obscureText, isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(password().obscureText, isFalse);
  });

  testWidgets('enter in the password field signs in', (tester) async {
    final api = FakeAuthApi();
    await pumpAuthApp(tester, api);

    await tester.enterText(find.byType(TextField).at(0), 'club1');
    await tester.enterText(find.byType(TextField).at(1), 'club1');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(api.logins, ['club1']);
  });

  // The focus follows what the eye sees: password, «Forgot…» right under it, then «Sign in».
  testWidgets('Tab goes from field to field and skips the eye button', (
    tester,
  ) async {
    await pumpAuthApp(tester, FakeAuthApi());
    bool focusedIn(Finder finder) => tester
        .widget<EditableText>(
          find.descendant(of: finder, matching: find.byType(EditableText)),
        )
        .focusNode
        .hasFocus;

    await tester.tap(find.byType(TextField).at(0));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(focusedIn(find.byType(TextField).at(1)), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    var focused = FocusManager.instance.primaryFocus!.context!;
    expect(focused.findAncestorWidgetOfExactType<IconButton>(), isNull);
    expect(focused.findAncestorWidgetOfExactType<TextButton>(), isNotNull);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    focused = FocusManager.instance.primaryFocus!.context!;
    expect(focused.findAncestorWidgetOfExactType<FilledButton>(), isNotNull);
  });
}
