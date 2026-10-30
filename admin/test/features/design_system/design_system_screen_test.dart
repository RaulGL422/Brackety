import 'package:brackety_admin/app.dart';
import 'package:brackety_admin/features/design_system/ui/design_system_screen.dart';
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
    testWidgets('design system page renders in light and dark on $device', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const ProviderScope(child: AdminApp()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Design').first);
      await tester.pumpAndSettle();

      expect(find.text('Design system'), findsOneWidget);
      for (final mode in ['Dark', 'Light']) {
        await tester.tap(find.text(mode));
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('scoreboard buttons change the score', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: AdminApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Design').first);
    await tester.pumpAndSettle();

    final fours = find.text('4').evaluate().length;
    await tester.tap(find.text('+1').first);
    await tester.pump();

    expect(find.text('4'), findsNWidgets(fours + 1));
  });

  testWidgets('list tiles in the preview can be tapped', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: AdminApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Design').first);
    await tester.pumpAndSettle();

    final tile = find.widgetWithText(SwitchListTile, 'Notifications');
    final page = find.descendant(
      of: find.byType(DesignSystemScreen),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(tile, 300, scrollable: page.first);
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(tile).value, isFalse);
  });
}
