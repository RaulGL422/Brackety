import 'package:brackety/core/download/file_download.dart';
import 'package:brackety/features/appearance/data/theme_store.dart';
import 'package:brackety/features/appearance/state/theme_mode_provider.dart';
import 'package:brackety/features/auth/data/account.dart';
import 'package:brackety/features/auth/data/registration.dart';
import 'package:brackety/features/auth/state/session_controller.dart';
import 'package:brackety/features/auth/ui/app_settings_screen.dart';
import 'package:brackety/features/auth/ui/settings_screen.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import 'auth_app.dart';

void main() {
  late FakeAuthApi auth;

  setUp(() => auth = FakeAuthApi(signedIn: true));

  Future<FakeAccountApi> openSettings(
    WidgetTester tester, {
    Account? account,
    bool devEnvironment = false,
    List<(String, List<int>)>? saved,
    ThemeStore? themes,
    ThemeMode savedTheme = ThemeMode.system,
    String location = '/settings',
  }) async {
    final api = FakeAccountApi(account: account);
    await pumpAuthApp(
      tester,
      auth,
      account: api,
      location: location,
      devEnvironment: devEnvironment,
      overrides: [
        saveFileProvider.overrideWithValue(
          (name, bytes, _) async => saved?.add((name, bytes)),
        ),
        if (themes != null) themeStoreProvider.overrideWithValue(themes),
        savedThemeModeProvider.overrideWithValue(savedTheme),
      ],
    );
    return api;
  }

  SessionStatus sessionStatus(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
          .read(sessionProvider)
          .status;

  Future<void> enterPassword(WidgetTester tester, String password) async {
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      password,
    );
    await tapText(tester, 'Confirm');
  }

  Future<void> scrollTo(WidgetTester tester, String text) =>
      tester.scrollUntilVisible(
        find.text(text),
        200,
        scrollable: find.byType(Scrollable).first,
      );

  for (final MapEntry(key: device, value: size) in screenSizes.entries) {
    testWidgets('every section shows and fits on $device', (tester) async {
      useSize(tester, size);
      await openSettings(tester);

      expect(find.text('My account'), findsOneWidget);
      expect(find.text('Sign-in'), findsOneWidget);
      expect(find.text('ana@example.com'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      // The device's own choices live in «Ajustes de la app».
      expect(find.text('Language'), findsNothing);
      for (final text in [
        'Helper',
        'Email and password',
        'Privacy and data',
        'Export my data',
        'Danger zone',
        'Delete account',
        'Sign out',
      ]) {
        await scrollTo(tester, text);
        expect(find.text(text), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final (title, location, last) in [
    ('My account', '/settings', 'Sign out'),
    ('App settings', '/app-settings', 'About Brackety'),
  ]) {
    testWidgets('text at 200 % fits $title on a phone', (tester) async {
      useSize(tester, screenSizes['phone']!);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openSettings(tester, location: location);

      await scrollTo(tester, last);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the account menu says who is in and opens my account', (
    tester,
  ) async {
    await pumpAuthApp(tester, auth);

    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    // Who is signed in heads the menu.
    expect(find.text('ana@example.com'), findsWidgets);
    await tester.tap(find.text('My account'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('the account menu opens the app settings', (tester) async {
    await pumpAuthApp(tester, auth);

    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('App settings'));
    await tester.pumpAndSettle();
    expect(find.byType(AppSettingsScreen), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
  });

  for (final MapEntry(key: device, value: size) in screenSizes.entries) {
    testWidgets('app settings show and fit on $device', (tester) async {
      useSize(tester, size);
      final handle = tester.ensureSemantics();
      await openSettings(tester, location: '/app-settings');

      expect(find.text('App settings'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      await scrollTo(tester, 'About Brackety');
      expect(find.text('Appearance'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }

  testWidgets('without the server it says so and retries', (tester) async {
    final api = FakeAccountApi()..meError = networkError();
    await pumpAuthApp(tester, auth, account: api, location: '/settings');

    expect(find.text('Cannot reach the server.'), findsOneWidget);

    api.meError = null;
    await tapText(tester, 'Retry');

    expect(find.text('ana@example.com'), findsOneWidget);
  });

  testWidgets('an unverified email can resend the link', (tester) async {
    await openSettings(tester, account: testAccount(emailVerified: false));

    expect(find.text('Not verified'), findsOneWidget);
    await tapText(tester, 'Resend the email');

    expect(auth.resends, ['ana@example.com']);
  });

  group('profiles', () {
    testWidgets('an organizer shows its organization and validation', (
      tester,
    ) async {
      await openSettings(
        tester,
        devEnvironment: true,
        account: testAccount(
          profiles: const [
            AccountProfile(
              type: ProfileType.club,
              organizationName: 'Club Yoseikan Sevilla',
              taxId: 'G41234567',
            ),
          ],
        ),
      );

      expect(find.text('Club Yoseikan Sevilla'), findsOneWidget);
      expect(find.text('Tax ID (CIF): G41234567'), findsOneWidget);
      expect(find.text('Pending validation'), findsOneWidget);
      expect(find.text('Add profile'), findsNothing);
    });

    testWidgets('a validated organizer says so', (tester) async {
      await openSettings(
        tester,
        account: testAccount(
          profiles: const [
            AccountProfile(
              type: ProfileType.externalEntity,
              validated: true,
              organizationName: 'Federación Andaluza',
              taxId: 'Q4100000J',
            ),
          ],
        ),
      );

      expect(find.text('Validated'), findsOneWidget);
    });

    testWidgets('adding one shows it in the list', (tester) async {
      final api = await openSettings(tester, devEnvironment: true);

      await tapText(tester, 'Student');

      expect(api.addedProfiles, [ProfileType.student]);
      expect(find.text('Profile added.'), findsOneWidget);
    });

    testWidgets('with Student and Helper nothing is offered', (tester) async {
      await openSettings(
        tester,
        devEnvironment: true,
        account: testAccount(
          profiles: const [
            AccountProfile(type: ProfileType.student),
            AccountProfile(type: ProfileType.helper),
          ],
        ),
      );

      expect(find.text('Add profile'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'External'), findsNothing);
    });

    testWidgets('outside dev only Helper is offered', (tester) async {
      await openSettings(
        tester,
        account: testAccount(
          profiles: const [AccountProfile(type: ProfileType.student)],
        ),
      );

      expect(find.widgetWithText(OutlinedButton, 'Helper'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'External'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Club'), findsNothing);
    });

    testWidgets('a forbidden combination is explained', (tester) async {
      final api = await openSettings(tester, devEnvironment: true);
      api.addProfileErrors.add(
        httpError(409, body: {'code': 'PROFILE_COMBINATION_NOT_ALLOWED'}),
      );

      await tapText(tester, 'External');

      expect(
        find.text('That profile cannot be combined with the ones you have.'),
        findsOneWidget,
      );
    });

    testWidgets('an unverified email cannot add profiles', (tester) async {
      final api = await openSettings(
        tester,
        devEnvironment: true,
        account: testAccount(emailVerified: false),
      );
      api.addProfileErrors.add(httpError(403));

      await tapText(tester, 'Student');

      expect(
        find.text('Verify your email before adding profiles.'),
        findsOneWidget,
      );
    });

    testWidgets('a token from before a verification is renewed and retried', (
      tester,
    ) async {
      final api = await openSettings(tester, devEnvironment: true);
      api.addProfileErrors.add(httpError(403));
      final refreshes = auth.refreshes.length;

      await tapText(tester, 'Student');

      expect(auth.refreshes.length, refreshes + 1);
      expect(api.addedProfiles, [ProfileType.student]);
    });

    testWidgets('the last one has no remove button', (tester) async {
      await openSettings(tester);

      expect(find.text('Helper'), findsOneWidget);
      expect(find.byTooltip('Remove profile'), findsNothing);
    });

    testWidgets('a LAST_PROFILE from the server is explained', (tester) async {
      final api = await openSettings(
        tester,
        account: testAccount(
          profiles: const [
            AccountProfile(type: ProfileType.helper),
            AccountProfile(type: ProfileType.student),
          ],
        ),
      );
      api.removeProfileError = httpError(409, body: {'code': 'LAST_PROFILE'});

      await tester.ensureVisible(find.byTooltip('Remove profile').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove profile').first);
      await tester.pumpAndSettle();
      expect(find.text('Remove the Helper profile?'), findsOneWidget);
      await tapText(tester, 'Remove');

      expect(
        find.text('Your account needs at least one profile.'),
        findsOneWidget,
      );
    });

    testWidgets('removing one takes it off the list', (tester) async {
      final api = await openSettings(
        tester,
        account: testAccount(
          profiles: const [
            AccountProfile(type: ProfileType.helper),
            AccountProfile(type: ProfileType.student),
          ],
        ),
      );

      await tester.ensureVisible(find.byTooltip('Remove profile').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove profile').last);
      await tester.pumpAndSettle();
      await tapText(tester, 'Remove');

      expect(api.removedProfiles, [ProfileType.student]);
      expect(find.text('Profile removed.'), findsOneWidget);
      expect(find.byTooltip('Remove profile'), findsNothing);
    });
  });

  group('change email', () {
    Future<void> askForNewEmail(WidgetTester tester) async {
      await tapText(tester, 'Change email');
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'new@example.com',
      );
      await tapText(tester, 'Send link');
    }

    testWidgets('sends the link after the password', (tester) async {
      final api = await openSettings(tester);

      await askForNewEmail(tester);
      expect(find.text("Confirm it's you"), findsOneWidget);
      await enterPassword(tester, 'wrong-password');
      expect(find.text('Wrong password.'), findsOneWidget);
      await enterPassword(tester, api.password);

      expect(api.actions, [('email:new@example.com', 'reauth-1')]);
      expect(
        find.text(
          'We have sent an email to new@example.com. Open its link to finish '
          'the change (it expires in 24 hours).',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a locked account shows its lock id in the dialog', (
      tester,
    ) async {
      final api = await openSettings(tester);
      api.reauthError = httpError(429, body: {'lockId': 'L-7K2F'});

      await askForNewEmail(tester);
      await enterPassword(tester, api.password);

      expect(find.textContaining('L-7K2F'), findsOneWidget);
      expect(api.actions, isEmpty);
    });

    testWidgets('cancelling the password does nothing', (tester) async {
      final api = await openSettings(tester);

      await askForNewEmail(tester);
      await tapText(tester, 'Cancel');

      expect(api.actions, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('appearance', () {
    ThemeMode appMode(WidgetTester tester) =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

    testWidgets('dark fixes the app dark and is saved on the device', (
      tester,
    ) async {
      final store = _FakeThemeStore();
      await openSettings(tester, themes: store, location: '/app-settings');
      expect(appMode(tester), ThemeMode.system);

      await scrollTo(tester, 'Dark');
      await tapText(tester, 'Dark');

      expect(appMode(tester), ThemeMode.dark);
      expect(store.saved, ThemeMode.dark);
      expect(
        Theme.of(tester.element(find.text('Appearance'))).brightness,
        Brightness.dark,
      );
    });

    testWidgets('the app starts with the saved choice', (tester) async {
      await openSettings(
        tester,
        savedTheme: ThemeMode.light,
        location: '/app-settings',
      );

      expect(appMode(tester), ThemeMode.light);
      await scrollTo(tester, 'Light');
      final segments = tester.widget<SegmentedButton<ThemeMode>>(
        find.byType(SegmentedButton<ThemeMode>),
      );
      expect(segments.selected, {ThemeMode.light});
    });
  });

  group('language', () {
    testWidgets('switching changes the app and the account', (tester) async {
      final api = await openSettings(tester, location: '/app-settings');

      await tapText(tester, 'Español');

      expect(api.locales, ['es']);
      expect(find.text('Ajustes de la app'), findsOneWidget);
      expect(find.text('Idioma'), findsOneWidget);
    });

    testWidgets('a failure puts the language back', (tester) async {
      final api = await openSettings(tester, location: '/app-settings');
      api.localeError = networkError();

      await tapText(tester, 'Español');

      expect(find.text('App settings'), findsOneWidget);
      expect(find.text('The language could not be changed.'), findsOneWidget);
    });
  });

  testWidgets('the export saves the JSON and asks the password once', (
    tester,
  ) async {
    final saved = <(String, List<int>)>[];
    final api = await openSettings(tester, saved: saved);

    await scrollTo(tester, 'Export my data');
    await tapText(tester, 'Export my data');
    await enterPassword(tester, api.password);
    await tapText(tester, 'Export my data');

    expect(api.reauths, hasLength(1));
    expect(saved.map((s) => s.$1), [
      exportFileName(DateTime.now()),
      exportFileName(DateTime.now()),
    ]);
  });

  group('delete account', () {
    Future<void> confirmDeletion(WidgetTester tester) async {
      await scrollTo(tester, 'Delete account');
      await tapText(tester, 'Delete account');
      expect(find.text('Delete your account?'), findsOneWidget);
      expect(find.textContaining('after 30 days'), findsWidgets);
      await tapText(tester, 'Delete account');
    }

    testWidgets('an owner of events is told to hand them over', (tester) async {
      final api = await openSettings(tester);
      api.actionErrors.add(httpError(409, body: {'code': 'OWNS_EVENTS'}));

      await confirmDeletion(tester);
      await enterPassword(tester, api.password);

      expect(find.textContaining('Hand them over'), findsOneWidget);
      expect(sessionStatus(tester), SessionStatus.signedIn);
    });

    testWidgets('signs out and says until when it can be restored', (
      tester,
    ) async {
      final api = await openSettings(tester);

      await confirmDeletion(tester);
      await enterPassword(tester, api.password);

      expect(api.actions.single.$1, 'delete');
      expect(sessionStatus(tester), SessionStatus.signedOut);
      expect(
        find.text(
          'Your account will be deleted on December 2, 2026. Sign in before '
          'then to restore it.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('an expired token asks the password again and retries', (
      tester,
    ) async {
      final api = await openSettings(tester);
      api.actionErrors.add(httpError(403, body: {'code': 'REAUTH_REQUIRED'}));

      await confirmDeletion(tester);
      await enterPassword(tester, api.password);
      expect(find.text("Confirm it's you"), findsOneWidget);
      await enterPassword(tester, api.password);

      expect(api.actions.map((a) => a.$2), ['reauth-1', 'reauth-2']);
      expect(sessionStatus(tester), SessionStatus.signedOut);
    });
  });

  group('Google', () {
    final withGoogle = testAccount(
      signInMethods: const [
        SignInMethod(method: SignInMethod.password),
        SignInMethod(method: SignInMethod.google, email: 'ana@gmail.com'),
      ],
    );

    testWidgets('a linked Google can be unlinked', (tester) async {
      final api = await openSettings(tester, account: withGoogle);
      await scrollTo(tester, 'ana@gmail.com');

      await tapText(tester, 'Unlink');
      await tapText(tester, 'Unlink');
      await enterPassword(tester, api.password);

      expect(api.actions.single.$1, 'unlinkGoogle');
      expect(find.text('Google unlinked.'), findsOneWidget);
      expect(find.text('ana@gmail.com'), findsNothing);
    });

    testWidgets('removing the password signs out', (tester) async {
      final api = await openSettings(tester, account: withGoogle);
      await scrollTo(tester, 'Remove password');

      await tapText(tester, 'Remove password');
      await tapText(tester, 'Remove password');
      await enterPassword(tester, api.password);

      expect(api.actions.single.$1, 'removePassword');
      expect(sessionStatus(tester), SessionStatus.signedOut);
      expect(
        find.text(
          'Password removed and sessions closed. You can now only sign in '
          'with Google.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('without Google there is nothing to unlink nor remove', (
      tester,
    ) async {
      await openSettings(tester);

      await scrollTo(tester, 'Email and password');
      expect(find.text('Remove password'), findsNothing);
      expect(find.text('Unlink'), findsNothing);
    });

    testWidgets('a Google-only account cannot confirm sensitive actions yet', (
      tester,
    ) async {
      final api = await openSettings(
        tester,
        account: testAccount(
          signInMethods: const [
            SignInMethod(method: SignInMethod.google, email: 'ana@gmail.com'),
          ],
        ),
      );
      await scrollTo(tester, 'Unlink');

      expect(find.text('Email and password'), findsNothing);
      await tapText(tester, 'Unlink');
      await tapText(tester, 'Unlink');

      expect(find.text("Confirm it's you"), findsNothing);
      expect(
        find.text(
          'This action needs you to confirm with Google, coming soon to the app.',
        ),
        findsOneWidget,
      );
      expect(api.actions, isEmpty);
    });
  });

  group('confirm email change link', () {
    testWidgets('a valid link confirms and signs out', (tester) async {
      await pumpAuthApp(
        tester,
        auth,
        location: '/confirm-email-change?token=t1',
      );

      expect(auth.emailChanges, ['t1']);
      expect(
        find.text(
          'Email changed. All sessions have been closed: sign in with the new '
          'email.',
        ),
        findsOneWidget,
      );
      expect(sessionStatus(tester), SessionStatus.signedOut);

      await tapText(tester, 'Go to sign in');
      expect(find.text('Create an account'), findsOneWidget);
    });

    testWidgets('an invalid link says so', (tester) async {
      auth
        ..signedIn = false
        ..confirmEmailChangeError = httpError(400);
      await pumpAuthApp(
        tester,
        auth,
        location: '/confirm-email-change?token=old',
      );

      expect(find.text('The link is invalid or has expired.'), findsOneWidget);
    });

    testWidgets('a link without token is invalid', (tester) async {
      await pumpAuthApp(tester, auth, location: '/confirm-email-change');

      expect(find.text('The link is invalid or has expired.'), findsOneWidget);
      expect(auth.emailChanges, isEmpty);
    });
  });

  testWidgets('the delete confirmation keeps a readable width on desktop', (
    tester,
  ) async {
    useSize(tester, const Size(1280, 900));
    await openSettings(tester);

    await scrollTo(tester, 'Delete account');
    await tapText(tester, 'Delete account');

    expect(
      tester
          .getSize(
            find
                .descendant(
                  of: find.byType(AlertDialog),
                  matching: find.byType(Material),
                )
                .first,
          )
          .width,
      lessThanOrEqualTo(AppSizes.formMaxWidth + 2 * AppSpacing.xl * 2),
    );
  });
}

class _FakeThemeStore implements ThemeStore {
  ThemeMode? saved;

  @override
  Future<ThemeMode> read() async => saved ?? ThemeMode.system;

  @override
  Future<void> write(ThemeMode mode) async => saved = mode;
}
