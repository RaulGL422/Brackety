import 'package:brackety/app.dart';
import 'package:brackety/core/router.dart';
import 'package:brackety/features/events/data/my_event.dart';
import 'package:brackety/features/events/state/events_providers.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  const sizes = {
    'phone': Size(360, 800),
    'tablet': Size(800, 1280),
    'desktop': Size(1440, 900),
  };

  Widget app(FakeAuthApi api, {FakeAccountApi? account}) => ProviderScope(
    overrides: [
      ...sessionOverrides(api, account: account),
      serverInfoProvider.overrideWith(
        (ref) async =>
            ServerInfo(name: 'brackety', today: DateTime(2027, 3, 10)),
      ),
      myEventsProvider.overrideWith(
        (ref) async => [
          MyEvent(
            id: 'e1',
            name: 'Liga Yoseikan · Fase 1',
            date: DateTime(2027, 3, 10),
            roles: const {EventRole.grouper},
            permissions: const {EventPermission.groups},
          ),
        ],
      ),
    ],
    child: const BracketyApp(),
  );

  for (final MapEntry(key: device, value: size) in sizes.entries) {
    testWidgets('sign in and see my events on $device', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final api = FakeAuthApi();

      await tester.pumpWidget(app(api));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'ayudante1');
      await tester.enterText(find.byType(TextField).at(1), 'wrong');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Wrong email or password.'), findsOneWidget);

      await tester.ensureVisible(find.widgetWithText(ActionChip, 'ayudante1'));
      await tester.tap(find.widgetWithText(ActionChip, 'ayudante1'));
      await tester.pumpAndSettle();

      expect(api.logins, ['ayudante1']);
      expect(find.text('Liga Yoseikan · Fase 1'), findsOneWidget);
      expect(find.text('Make groups'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'a saved session skips the sign-in; a support account finds Connection in the settings',
    (tester) async {
      final support = FakeAccountApi(account: testAccount(support: true));
      await tester.pumpWidget(
        app(FakeAuthApi(signedIn: true), account: support),
      );
      await tester.pumpAndSettle();

      expect(find.text('My events'), findsOneWidget);
      expect(
        find.text('Verify your email: some actions need it.'),
        findsNothing,
      );

      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      expect(find.text('Connection'), findsNothing);
      await tester.tap(find.text('App settings'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Connection'), 300);
      await tester.ensureVisible(find.text('Connection'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Connection'));
      await tester.pumpAndSettle();
      expect(find.text(apiBaseUrl), findsOneWidget);
      expect(find.text('Server date: March 10, 2027'), findsOneWidget);
    },
  );

  // Raul, 2026-11-25: the Connection screen is not for customers.
  testWidgets('a customer finds no Connection, and its address goes home', (
    tester,
  ) async {
    await tester.pumpWidget(app(FakeAuthApi(signedIn: true)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('App settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Software licenses'), 300);
    expect(find.text('Connection'), findsNothing);

    ProviderScope.containerOf(tester.element(find.byType(BracketyApp)))
        .read(routerProvider)
        .go('/connection');
    await tester.pumpAndSettle();
    expect(find.text('My events'), findsOneWidget);
  });

  for (final MapEntry(key: device, value: size) in sizes.entries) {
    testWidgets(
      'an unverified email shows the banner over the app on $device',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final api = FakeAuthApi(signedIn: true)..emailVerified = false;

        await tester.pumpWidget(app(api));
        await tester.pumpAndSettle();

        expect(
          find.text('Verify your email: some actions need it.'),
          findsOneWidget,
        );
        expect(find.text('My events'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('signed-in users are sent away from the sign-in and sign-up', (
    tester,
  ) async {
    await tester.pumpWidget(app(FakeAuthApi(signedIn: true)));
    await tester.pumpAndSettle();
    final router = ProviderScope.containerOf(
      tester.element(find.byType(BracketyApp)),
    ).read(routerProvider);

    router.go('/register');
    await tester.pumpAndSettle();
    expect(find.text('My events'), findsOneWidget);

    router.go('/forgot-password');
    await tester.pumpAndSettle();
    expect(find.text('Forgot your password?'), findsOneWidget);
  });

  testWidgets('signing out goes back to the sign-in', (tester) async {
    final api = FakeAuthApi(signedIn: true);
    await tester.pumpWidget(app(api));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    expect(api.logouts, [null]);
  });
}
