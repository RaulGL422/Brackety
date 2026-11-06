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
    testWidgets('a legal page renders its markdown and a wide table fits on '
        '$device', (tester) async {
      useSize(tester, size);
      final legal = FakeLegalRepository()..markdown = _wideTable;
      await openPage(tester, 'privacy', legal: legal);

      expect(find.widgetWithText(AppBar, 'Privacy policy'), findsOneWidget);
      expect(find.text('privacy (en)'), findsOneWidget);
      expect(find.byType(Table), findsOneWidget);
      expect(legal.texts.single, (LegalDocumentType.privacy, 'en'));
      expect(
        find.ancestor(
          of: find.byType(Table),
          matching: find.byWidgetPredicate(_scrollsSideways),
        ),
        size.width < 600 ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
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
        expect(find.widgetWithText(OutlinedButton, title), findsOneWidget);
      }
      expect(
        find.widgetWithText(OutlinedButton, 'Cookie policy'),
        findsNothing,
      );

      await tapText(tester, 'Legal notice');

      expect(find.widgetWithText(AppBar, 'Legal notice'), findsOneWidget);
      expect(find.text('legal-notice (en)'), findsOneWidget);
      expect(legal.texts.last, (LegalDocumentType.legalNotice, 'en'));
      expect(tester.takeException(), isNull);
    });
  }

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
