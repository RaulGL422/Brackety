import 'package:brackety/features/server/data/server_choice.dart';
import 'package:brackety/features/server/state/server_providers.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../auth/auth_app.dart';
import 'server_fakes.dart';

void main() {
  Future<FakeServerStore> pumpLogin(
    WidgetTester tester, {
    String? saved,
    bool selectable = true,
  }) async {
    final store = FakeServerStore()..url = saved;
    await pumpAuthApp(
      tester,
      FakeAuthApi(),
      overrides: [
        serverStoreProvider.overrideWithValue(store),
        serverSelectableProvider.overrideWithValue(selectable),
        ...serverOverrides(saved),
        serverInfoProvider.overrideWith(
          (ref) async =>
              ServerInfo(name: 'brackety', today: DateTime(2026, 10, 31)),
        ),
      ],
    );
    return store;
  }

  Finder urlField() => find.widgetWithText(TextFormField, 'Server URL');

  for (final MapEntry(key: device, value: size) in screenSizes.entries) {
    testWidgets('picks a typed server from the sign-in on $device', (
      tester,
    ) async {
      useSize(tester, size);
      final store = await pumpLogin(tester, saved: hallServerUrl);

      expect(find.text('Server: Sports hall'), findsOneWidget);
      await tapText(tester, 'Change');
      expect(find.text(internetServerUrl), findsOneWidget);

      await tester.tap(find.text('Other URL'));
      await tester.pumpAndSettle();
      await tester.enterText(urlField(), 'api.example.com');
      await tapText(tester, 'Use');
      expect(
        find.text('Type a URL starting with http:// or https:// with a host.'),
        findsOneWidget,
      );

      await tester.enterText(urlField(), 'http://192.168.1.50:8080/');
      await tester.pump();
      expect(find.textContaining('will not connect'), findsOneWidget);
      await tapText(tester, 'Use');

      expect(store.url, 'http://192.168.1.50:8080');
      expect(find.text('Server: Other URL'), findsOneWidget);
      expect(find.text('http://192.168.1.50:8080'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a known server needs no URL and cancel changes nothing', (
    tester,
  ) async {
    final store = await pumpLogin(tester);

    await tapText(tester, 'Change');
    await tapText(tester, 'Cancel');
    expect(store.url, isNull);

    await tapText(tester, 'Change');
    await tester.tap(find.text('Sports hall'));
    await tester.pumpAndSettle();
    expect(urlField(), findsNothing);
    await tapText(tester, 'Use');

    expect(store.url, hallServerUrl);
    expect(find.text('Server: Sports hall'), findsOneWidget);
  });

  testWidgets('the connection screen shows the chosen server', (tester) async {
    await pumpLogin(tester, saved: hallServerUrl);

    await tester.tap(find.byTooltip('Connection'));
    await tester.pumpAndSettle();

    expect(find.text(hallServerUrl), findsOneWidget);
  });

  testWidgets('the web has no server choice', (tester) async {
    await pumpLogin(tester, saved: hallServerUrl, selectable: false);

    expect(find.text('Change'), findsNothing);
    expect(find.textContaining('Server:'), findsNothing);
  });
}
