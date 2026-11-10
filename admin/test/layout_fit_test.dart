import 'package:brackety_admin/features/locks/data/locks_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

// Real fonts come from flutter_test_config.dart, so these widths are the ones Chrome draws.
void main() {
  void useSpanish(WidgetTester tester) {
    tester.platformDispatcher.localesTestValue = const [Locale('es')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  }

  RenderParagraph paragraph(WidgetTester tester, Finder text) =>
      tester.renderObject<RenderParagraph>(
        find.descendant(of: text, matching: find.byType(RichText)).first,
      );

  /// Neither wrapped nor cut: the whole line fits in the space it got.
  void expectWholeLine(WidgetTester tester, Finder text) {
    for (final element in text.evaluate()) {
      final p = paragraph(tester, find.byWidget(element.widget));
      expect(
        p.getMaxIntrinsicWidth(double.infinity),
        lessThanOrEqualTo(p.size.width + 0.5),
        reason: '"${(element.widget as Text).data}" is clipped or wrapped',
      );
    }
  }

  void expectOneLine(WidgetTester tester, Finder text) {
    final p = paragraph(tester, text);
    final line = p.getFullHeightForCaret(const TextPosition(offset: 0));
    expect(p.size.height, lessThan(line * 1.5));
  }

  for (final spanish in [true, false]) {
    testWidgets(
      'phone bottom bar never wraps a label (${spanish ? 'es' : 'en'})',
      (tester) async {
        useSize(tester, screenSizes['phone']!);
        if (spanish) useSpanish(tester);
        await pumpAdmin(tester);

        final bar = find.byType(NavigationBar);
        final labels = find.descendant(of: bar, matching: find.byType(Text));
        final shown =
            tester.widget<NavigationBar>(bar).labelBehavior !=
            NavigationDestinationLabelBehavior.alwaysHide;
        if (shown) expectWholeLine(tester, labels);
        // Debug builds add Diseño: six tabs leave 60 px, and neither "Organizadores" (82) nor
        // "Organizers" fit, so the bar shows icons only (their labels are the tooltips).
        expect(shown, isFalse);
      },
    );
  }

  final organizers = FakeOrganizersApi([
    organizer('club', name: 'Club Deportivo Ejemplo', taxId: 'G12345674'),
    organizer('club.validado', name: 'Club Validado', validated: true),
  ]);
  final locks = FakeLocksApi([
    lock('L-7K2F', LockType.admin),
    lock(
      'L-9ABC',
      LockType.email,
      email: 'bloqueada.con.un.email.muy.largo.de.verdad@example.test',
    ),
  ]);

  for (final width in [1280.0, 840.0]) {
    testWidgets('organizer state chips are whole at $width px', (tester) async {
      useSize(tester, Size(width, 900));
      useSpanish(tester);
      await pumpAdmin(tester, organizers: organizers, location: '/organizers');
      await tester.tap(find.widgetWithText(ChoiceChip, 'Todos'));
      await tester.pumpAndSettle();

      expectWholeLine(tester, find.text('Pendiente'));
      expectWholeLine(tester, find.text('Validado'));
      expectWholeLine(tester, find.text('Validar'));
    });

    testWidgets('lock type chips are whole at $width px', (tester) async {
      useSize(tester, Size(width, 900));
      useSpanish(tester);
      await pumpAdmin(tester, locks: locks, location: '/locks');

      expectWholeLine(tester, find.text('Superadmin'));
      expectWholeLine(tester, find.text('Revocar'));
    });
  }

  testWidgets('table emails stay on one line', (tester) async {
    useSize(tester, const Size(1280, 900));
    await pumpAdmin(tester, organizers: organizers, location: '/organizers');
    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();

    expectOneLine(tester, find.text('club.validado@example.test'));
    expect(find.byTooltip('club.validado@example.test'), findsOneWidget);
  });

  testWidgets('the locks "who" column stays on one line', (tester) async {
    useSize(tester, const Size(1280, 900));
    await pumpAdmin(tester, locks: locks, location: '/locks');

    expectOneLine(
      tester,
      find.text('bloqueada.con.un.email.muy.largo.de.verdad@example.test'),
    );
  });
}
