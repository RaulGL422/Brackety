import 'package:brackety/core/download/file_download.dart';
import 'package:brackety/core/upload/file_upload.dart';
import 'package:brackety/features/rulebook/rulebook.dart';
import 'package:brackety/features/rulebook/rulebook_ui.dart';
import 'package:brackety/l10n/gen/app_localizations.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRulebooks extends RulebookRepository {
  _FakeRulebooks() : super(Dio());

  String? name;
  List<int>? bytes;

  @override
  Future<String?> fileName(String eventId) async => name;

  @override
  Future<List<int>?> pdf(String eventId) async => bytes;

  @override
  Future<void> upload(String eventId, String name, List<int> bytes) async {
    this.name = name;
    this.bytes = bytes;
  }

  @override
  Future<void> delete(String eventId) async {
    name = null;
    bytes = null;
  }
}

void main() {
  late _FakeRulebooks rulebooks;
  late List<List<int>> opened;

  Widget app(Widget child) => ProviderScope(
    overrides: [
      rulebookRepositoryProvider.overrideWithValue(rulebooks),
      pickFilesProvider.overrideWithValue(
        ({required accept, required multiple}) async => [
          const PickedFile(name: 'Reglamento F1.pdf', bytes: [37, 80, 68, 70]),
        ],
      ),
      openPdfProvider.overrideWithValue((name, bytes) async {
        opened.add(await bytes);
      }),
    ],
    child: MaterialApp(
      builder: (_, child) => ToastHost(child: child!),
      theme: lightTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...coreLocalizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );

  setUp(() {
    rulebooks = _FakeRulebooks();
    opened = [];
  });

  testWidgets('the club uploads the rulebook and can open or remove it', (
    tester,
  ) async {
    await tester.pumpWidget(app(const RulebookSection(eventId: 'e1')));
    await tester.pumpAndSettle();
    expect(find.text('No rulebook'), findsOneWidget);

    await tester.tap(find.text('Upload PDF'));
    await tester.pumpAndSettle();
    expect(find.text('Reglamento F1.pdf'), findsOneWidget);
    expect(find.text('Replace PDF'), findsOneWidget);

    await tester.tap(find.text('Open rulebook'));
    await tester.pumpAndSettle();
    expect(opened.single, [37, 80, 68, 70]);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('No rulebook'), findsOneWidget);
  });

  testWidgets('the referee sees the button only when the phase has one', (
    tester,
  ) async {
    await tester.pumpWidget(app(const RulebookButton(eventId: 'e1')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.menu_book_outlined), findsNothing);

    rulebooks.bytes = [1, 2, 3];
    await tester.pumpWidget(
      app(const RulebookButton(key: ValueKey('again'), eventId: 'e2')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();
    expect(opened.single, [1, 2, 3]);
  });
}
