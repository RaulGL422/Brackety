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
      await pumpAuthApp(tester, FakeAuthApi());

      expect(find.text('Forgot your password?'), findsOneWidget);
      expect(find.text('No account? Sign up'), findsOneWidget);
      expect(find.text('Test accounts (development only)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

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
    expect(find.text('No account? Sign up'), findsOneWidget);
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
    final focused = FocusManager.instance.primaryFocus!.context!;
    expect(focused.findAncestorWidgetOfExactType<IconButton>(), isNull);
    expect(focused.findAncestorWidgetOfExactType<FilledButton>(), isNotNull);
  });
}
