import 'package:brackety/features/legal/data/legal_repository.dart';
import 'package:brackety/features/legal/ui/external_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/legal_fakes.dart';
import '../auth/auth_app.dart';

const _wideTable = '''
| Purpose | Legal basis | Where | How long |
|---|---|---|---|
| Organising events: entries, groups, scoreboard and standings | Contract with the organizer; guardian consent for minors | Web and Android app | Until the account is deleted |
''';

// As the server sends them (Raul, 2026-11-25): a summary, then numbered sections.
const _structured =
    '''
> **In short**
>
> - We do not use your data for advertising.

This policy explains which data Brackety processes.

## 1. Controller

The owner.

## 2. Purposes

$_wideTable

## 3. Your rights

You can ask to see your data.
''';

bool _scrollsSideways(Widget widget) =>
    widget is SingleChildScrollView &&
    widget.scrollDirection == Axis.horizontal;

void main() {
  Future<FakeLegalRepository> openPage(
    WidgetTester tester,
    String slug, {
    FakeLegalRepository? legal,
    bool signedIn = false,
  }) async {
    final repository = legal ?? FakeLegalRepository();
    await pumpAuthApp(
      tester,
      FakeAuthApi(signedIn: signedIn),
      location: '/legal/$slug',
      legal: repository,
    );
    return repository;
  }

  for (final MapEntry(key: device, value: size) in screenSizes.entries) {
    testWidgets('a legal page reads well and its table fits on $device', (
      tester,
    ) async {
      useSize(tester, size);
      final handle = tester.ensureSemantics();
      final legal = FakeLegalRepository()..markdown = _structured;
      await openPage(tester, 'privacy', legal: legal);

      // The title once, as the heading: not again in the bar.
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.byType(Text)),
        findsNothing,
      );
      expect(
        tester.getSemantics(find.text('privacy (en)')),
        matchesSemantics(label: 'privacy (en)', isHeader: true),
      );
      expect(find.text('Version of November 4, 2026'), findsOneWidget);
      expect(find.text('On this page'), findsOneWidget);
      expect(find.text('Controller'), findsOneWidget);
      expect(legal.texts.single, (LegalDocumentType.privacy, 'en'));
      // On a phone each row is a block; wider, a table. Nothing scrolls sideways.
      expect(
        find.byType(Table),
        size.width < 600 ? findsNothing : findsOneWidget,
      );
      expect(find.byWidgetPredicate(_scrollsSideways), findsNothing);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      expect(tester.takeException(), isNull);
      handle.dispose();
    });

    testWidgets('the contents take you to a section on $device', (
      tester,
    ) async {
      useSize(tester, size);
      // Long enough to scroll on any window.
      final legal = FakeLegalRepository()
        ..markdown = _structured
            .replaceFirst(
              'The owner.',
              List.filled(60, 'The owner.').join('\n\n'),
            )
            .replaceFirst(
              'You can ask to see your data.',
              List.filled(60, 'You can ask to see your data.').join('\n\n'),
            );
      await openPage(tester, 'privacy', legal: legal);
      final heading = find.text('3. Your rights');
      expect(tester.getTopLeft(heading).dy, greaterThan(size.height));

      await tester.tap(find.text('Your rights'));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(heading).dy, lessThan(size.height / 2));
    });

    testWidgets('a failed load offers a retry on $device', (tester) async {
      useSize(tester, size);
      final legal = FakeLegalRepository()..textError = networkError();
      await openPage(tester, 'terms', legal: legal);

      expect(
        find.text('Could not load. Check the connection.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      legal.textError = null;
      await tapText(tester, 'Retry');

      expect(find.text('terms (en)'), findsOneWidget);
      expect(legal.texts, hasLength(2));
    });

    testWidgets('the page links to the other three documents on $device', (
      tester,
    ) async {
      useSize(tester, size);
      final legal = await openPage(tester, 'cookies');

      for (final title in ['Privacy policy', 'Terms of use', 'Legal notice']) {
        expect(find.widgetWithText(ListTile, title), findsOneWidget);
      }
      expect(find.widgetWithText(ListTile, 'Cookie policy'), findsNothing);

      await tester.ensureVisible(find.widgetWithText(ListTile, 'Legal notice'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Legal notice'));
      await tester.pumpAndSettle();

      expect(find.text('legal-notice (en)'), findsOneWidget);
      expect(legal.texts.last, (LegalDocumentType.legalNotice, 'en'));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('text at 200 % fits a legal page on a phone', (tester) async {
    useSize(tester, screenSizes['phone']!);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final legal = FakeLegalRepository()..markdown = _structured;
    await openPage(tester, 'privacy', legal: legal);

    await tester.scrollUntilVisible(
      find.text('Back to contents'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unknown page says it does not exist', (tester) async {
    final legal = await openPage(tester, 'secrets');

    expect(find.text('This legal page does not exist.'), findsOneWidget);
    expect(legal.texts, isEmpty);
  });

  testWidgets('the pages open with a session too', (tester) async {
    await openPage(tester, 'terms', signedIn: true);

    expect(find.text('terms (en)'), findsOneWidget);
  });

  test('only http(s) and mailto links leave the app', () {
    expect(externalLink('https://rgal.dev'), isNotNull);
    expect(externalLink('http://rgal.dev'), isNotNull);
    expect(externalLink('mailto:privacidad@example.com'), isNotNull);
    expect(externalLink('javascript:alert(1)'), isNull);
    expect(externalLink('file:///etc/passwd'), isNull);
    expect(externalLink('/legal/terms'), isNull);
    expect(externalLink(null), isNull);
  });
}
