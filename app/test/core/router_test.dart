import 'package:brackety/app.dart';
import 'package:brackety/core/router.dart';
import 'package:brackety/features/events/state/events_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

/// A reload on the web opens the app at the address it had: the session is checked first
/// (and asked for when it is gone), then the screen comes back.
void main() {
  Future<String> openAt(
    WidgetTester tester,
    String address,
    FakeAuthApi api, {
    Future<void> Function()? meanwhile,
  }) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = address;
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...sessionOverrides(api),
          myEventsProvider.overrideWith((ref) async => []),
        ],
        child: const BracketyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await meanwhile?.call();
    return location(tester);
  }

  testWidgets('a reload with the session alive comes back to the same screen', (
    tester,
  ) async {
    final at = await openAt(tester, '/settings', FakeAuthApi(signedIn: true));

    expect(at, '/settings');
  });

  testWidgets('without a session it signs in first, then goes back there', (
    tester,
  ) async {
    final at = await openAt(
      tester,
      '/settings',
      FakeAuthApi(),
      meanwhile: () async {
        expect(location(tester), startsWith('/login?from='));
        await tester.ensureVisible(
          find.widgetWithText(ActionChip, 'ayudante1'),
        );
        await tester.tap(find.widgetWithText(ActionChip, 'ayudante1'));
        await tester.pumpAndSettle();
      },
    );

    expect(at, '/settings');
  });

  // Raul, 2026-11-25: reloading the sign-in again and again piled up «/login?from=/login?from=…».
  testWidgets('reloading the sign-in keeps one "from"', (tester) async {
    final at = await openAt(
      tester,
      '/login?from=${Uri.encodeQueryComponent('/settings')}',
      FakeAuthApi(),
    );

    expect(at, '/login?from=${Uri.encodeQueryComponent('/settings')}');
  });

  testWidgets('an address already piled up comes down to its destination', (
    tester,
  ) async {
    final inner = '/login?from=${Uri.encodeQueryComponent('/settings')}';
    final at = await openAt(
      tester,
      '/login?from=${Uri.encodeQueryComponent(inner)}',
      FakeAuthApi(),
    );

    expect(at, '/login?from=${Uri.encodeQueryComponent('/settings')}');
  });

  testWidgets('reloading the sign-up stays on the sign-up', (tester) async {
    final at = await openAt(tester, '/register', FakeAuthApi());

    expect(at, '/register');
  });

  testWidgets('a "from" that leaves the app is ignored', (tester) async {
    final at = await openAt(
      tester,
      '/loading?from=//evil.example/x',
      FakeAuthApi(signedIn: true),
    );

    expect(at, '/');
  });
}

String location(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(BracketyApp)))
        .read(routerProvider)
        .routerDelegate
        .currentConfiguration
        .uri
        .toString();
