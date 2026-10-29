import 'package:brackety_admin/app.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sizes = {
    'phone': Size(360, 800),
    'tablet': Size(800, 1280),
    'desktop': Size(1440, 900),
  };

  for (final MapEntry(key: device, value: size) in sizes.entries) {
    testWidgets('dashboard and connection work on $device', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            serverInfoProvider.overrideWith(
              (ref) async =>
                  ServerInfo(name: 'brackety', today: DateTime(2027, 3, 10)),
            ),
          ],
          child: const AdminApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Superadmin dashboard'), findsOneWidget);

      await tester.tap(find.text('Connection').first);
      await tester.pumpAndSettle();

      expect(find.text(apiBaseUrl), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
