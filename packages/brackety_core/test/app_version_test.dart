import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  setUp(
    () => PackageInfo.setMockInitialValues(
      appName: 'Brackety',
      packageName: 'dev.rgal.brackety',
      version: '0.6.0',
      buildNumber: '8',
      buildSignature: '',
    ),
  );

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: coreLocalizationsDelegates,
        supportedLocales: const [Locale('es'), Locale('en')],
        locale: const Locale('es'),
        home: AdaptiveScaffold(
          title: 'Brackety',
          destinations: const [
            AdaptiveDestination(icon: Icons.home, label: 'Inicio'),
            AdaptiveDestination(icon: Icons.dns, label: 'Servidor'),
          ],
          selectedIndex: 0,
          onSelected: (_) {},
          body: const Text('body'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final (device, size) in [
    ('tablet', const Size(800, 1280)),
    ('desktop', const Size(1440, 900)),
  ]) {
    testWidgets('the side panel shows the version on $device', (tester) async {
      await pumpAt(tester, size);

      expect(find.text('Versión 0.6.0 (8)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the phone bottom bar has no side panel to show it in', (
    tester,
  ) async {
    await pumpAt(tester, const Size(360, 800));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Versión 0.6.0 (8)'), findsNothing);
  });
}
