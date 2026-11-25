import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _changelog = '''
# Cambios

Lo que trae cada versión, para saber qué probar.

## Sin publicar (en debug)

### Nuevo
- Árbitro por QR que pierde la sesión: vuelve a entrar solo con la contraseña (#173).
- Exportar a medida con vista previa (#191).

### Arreglos
- Un tapiz sin árbitro admite grupos (#169).

## 0.8.2 y anteriores
En las etiquetas de GitHub.
''';

void main() {
  group('the changelog', () {
    final entries = parseChangelog(_changelog);

    test('keeps each change with its release and kind, and nothing else', () {
      expect(entries, hasLength(3));
      expect(entries.first.release, 'Sin publicar (en debug)');
      expect(entries.first.kind, 'Nuevo');
      expect(entries.last.kind, 'Arreglos');
      expect(entries.last.text, 'Un tapiz sin árbitro admite grupos (#169).');
    });

    test('is searched by every word, without case or accents', () {
      List<String> found(String query) => [
        for (final e in entries)
          if (e.matches(query)) e.text,
      ];

      expect(found('arbitro'), hasLength(2));
      expect(found('ÁRBITRO qr'), [entries.first.text]);
      expect(found('arreglos tapiz'), [entries.last.text]);
      expect(found('#191'), [entries[1].text]);
      expect(found('  '), hasLength(3));
      expect(found('pagos'), isEmpty);
    });
  });

  Future<void> pump(
    WidgetTester tester, {
    String? markdown = _changelog,
    Size size = const Size(360, 800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          changelogProvider.overrideWith(
            (ref) async => markdown == null ? null : parseChangelog(markdown),
          ),
        ],
        child: MaterialApp(
          theme: lightTheme(),
          localizationsDelegates: coreLocalizationsDelegates,
          supportedLocales: const [Locale('es'), Locale('en')],
          locale: const Locale('en'),
          home: const Scaffold(body: ChangelogView()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final (device, size) in [
    ('phone', const Size(360, 800)),
    ('tablet', const Size(800, 1280)),
    ('desktop', const Size(1440, 900)),
  ]) {
    testWidgets('the changes and their search on $device', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, size: size);

      expect(find.text('Sin publicar (en debug)'), findsOneWidget);
      expect(find.text('3 of 3 changes'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'tapiz');
      await tester.pumpAndSettle();
      expect(find.text('1 of 3 changes'), findsOneWidget);
      expect(find.text('Arreglos'), findsOneWidget);
      expect(find.text('Nuevo'), findsNothing);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }

  testWidgets(
    'no change with those words says so, and clearing brings all back',
    (tester) async {
      await pump(tester);

      await tester.enterText(find.byType(TextField), 'pagos');
      await tester.pumpAndSettle();
      expect(find.text('No change has all those words.'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear the search'));
      await tester.pumpAndSettle();
      expect(find.text('3 of 3 changes'), findsOneWidget);
    },
  );

  testWidgets('outside a debug build it says where the list lives', (
    tester,
  ) async {
    await pump(tester, markdown: null);

    expect(
      find.textContaining('only comes in the debug builds'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('text at 200 % fits on a phone', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(tester);

    expect(find.text('3 of 3 changes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
