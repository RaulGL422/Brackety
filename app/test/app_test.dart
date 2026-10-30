import 'package:brackety/app.dart';
import 'package:brackety/features/events/data/my_event.dart';
import 'package:brackety/features/events/state/events_providers.dart';
import 'package:brackety/features/session/state/session_controller.dart';
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

  Widget app(FakeSessionApi sessions) => ProviderScope(
    overrides: [
      sessionApiProvider.overrideWithValue(sessions),
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
            maxGroupsPerMat: 1,
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
      final sessions = FakeSessionApi(signedIn: false);

      await tester.pumpWidget(app(sessions));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'ayudante1');
      await tester.enterText(find.byType(TextField).at(1), 'wrong');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Wrong username or password.'), findsOneWidget);

      await tester.tap(find.widgetWithText(ActionChip, 'ayudante1'));
      await tester.pumpAndSettle();

      expect(sessions.logins, ['ayudante1']);
      expect(find.text('Liga Yoseikan · Fase 1'), findsOneWidget);
      expect(find.text('Make groups'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'a saved session skips the sign-in and the connection screen is reachable',
    (tester) async {
      await tester.pumpWidget(app(FakeSessionApi(signedIn: true)));
      await tester.pumpAndSettle();

      expect(find.text('My events'), findsOneWidget);

      await tester.tap(find.byTooltip('Connection'));
      await tester.pumpAndSettle();
      expect(find.text(apiBaseUrl), findsOneWidget);
      expect(find.text('Server date: March 10, 2027'), findsOneWidget);
    },
  );
}
