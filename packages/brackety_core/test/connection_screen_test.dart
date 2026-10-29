import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Future<ServerInfo> Function() fetch,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [serverInfoProvider.overrideWith((ref) => fetch())],
        child: const MaterialApp(
          locale: Locale('es'),
          supportedLocales: CoreLocalizations.supportedLocales,
          localizationsDelegates: coreLocalizationsDelegates,
          home: Scaffold(body: ConnectionScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the server url and the server day', (tester) async {
    await pump(
      tester,
      () async => ServerInfo(name: 'brackety', today: DateTime(2027, 3, 10)),
    );

    expect(find.text(apiBaseUrl), findsOneWidget);
    expect(find.text('Conectado'), findsOneWidget);
    expect(
      find.text('Fecha del servidor: 10 de marzo de 2027'),
      findsOneWidget,
    );
  });

  testWidgets('offers a retry when the server is unreachable', (tester) async {
    var calls = 0;
    await pump(tester, () async {
      calls++;
      throw Exception('offline');
    });

    expect(find.text('Sin conexión con el servidor'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(calls, 2);
  });

  test('parses the info response', () {
    final info = ServerInfo.fromJson({
      'name': 'brackety',
      'today': '2027-03-10',
    });

    expect(info.today, DateTime(2027, 3, 10));
  });
}
