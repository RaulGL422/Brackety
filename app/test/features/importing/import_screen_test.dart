import 'package:brackety/core/download/file_download.dart';
import 'package:brackety/core/upload/file_upload.dart';
import 'package:brackety/features/importing/data/import_models.dart';
import 'package:brackety/features/importing/data/import_repository.dart';
import 'package:brackety/features/importing/ui/import_screen.dart';
import 'package:brackety/l10n/gen/app_localizations.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers like the server: a row is valid once its category is settled.
class FakeImportRepository implements ImportRepository {
  FakeImportRepository(this.readRows);

  final List<CheckedRow> readRows;
  final sentFiles = <List<String>>[];
  final checked = <List<ImportRow>>[];
  final registered = <List<ImportRow>>[];
  var refuseRegister = false;

  @override
  Future<bool> isAvailable(String eventId) async => true;

  @override
  Future<List<CheckedRow>> read(
    String eventId, {
    required List<PickedFile> files,
    required String text,
  }) async {
    sentFiles.add([for (final f in files) f.name]);
    return readRows;
  }

  @override
  Future<List<CheckedRow>> check(String eventId, List<ImportRow> rows) async {
    checked.add(rows);
    return [for (final r in rows) _valid(r)];
  }

  @override
  Future<RegisterResult> register(String eventId, List<ImportRow> rows) async {
    if (refuseRegister) {
      return (
        registered: 0,
        rows: [
          CheckedRow(
            row: rows.first,
            errors: const [
              RowIssue(field: 'firstName', code: IssueCode.alreadyRegistered),
            ],
          ),
        ],
      );
    }
    registered.add(rows);
    return (registered: rows.length, rows: [for (final r in rows) _valid(r)]);
  }

  static CheckedRow _valid(ImportRow r) =>
      CheckedRow(row: r, age: 9, categoryName: '9-10');
}

void main() {
  const sizes = {
    'phone': Size(360, 800),
    'tablet': Size(800, 1280),
    'desktop': Size(1440, 900),
  };

  final ana = ImportRow(
    firstName: 'Ana',
    lastName: 'Prueba',
    birthDate: DateTime(2018),
    heightCm: 130,
  );
  final bea = ImportRow(
    firstName: 'Bea',
    lastName: 'Prueba',
    birthDate: DateTime(2018),
    categoryText: '7-8',
  );
  final readRows = [
    CheckedRow(row: ana, age: 9, categoryName: '9-10'),
    CheckedRow(
      row: bea,
      age: 9,
      indicatedCategoryId: 'c78',
      indicatedCategoryName: '7-8',
      ageCategoryId: 'c910',
      ageCategoryName: '9-10',
      errors: const [
        RowIssue(
          field: 'category',
          code: IssueCode.categoryMismatch,
          detail: '7-8',
        ),
      ],
      warnings: const [RowIssue(field: 'lastName', code: IssueCode.unsure)],
    ),
  ];

  Future<FakeImportRepository> open(
    WidgetTester tester,
    Size size, {
    List<String>? saved,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = FakeImportRepository(readRows);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          importRepositoryProvider.overrideWithValue(repository),
          pickFilesProvider.overrideWithValue(
            ({required accept, required multiple}) async => const [
              PickedFile(name: 'lista1.jpg', bytes: [1]),
              PickedFile(name: 'lista2.jpg', bytes: [2]),
            ],
          ),
          saveFileProvider.overrideWithValue(
            (name, bytes, mimeType) async => saved?.add(name),
          ),
        ],
        child: MaterialApp(
          theme: lightTheme(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...coreLocalizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ImportScreen(eventId: 'e1'),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return repository;
  }

  Future<void> readList(WidgetTester tester) async {
    await tester.tap(find.text('Choose photos'));
    await tester.pumpAndSettle();
    final read = find.widgetWithText(FilledButton, 'Read list');
    await tester.scrollUntilVisible(
      read,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<FilledButton>(read).onPressed, isNull);
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.ensureVisible(read);
    await tester.tap(read);
    await tester.pumpAndSettle();
  }

  testWidgets('the consent step links to the privacy policy', (tester) async {
    await open(tester, sizes['phone']!);

    final notice = find.text(
      "The students' data is handled according to the privacy policy.",
    );
    await tester.scrollUntilVisible(
      notice,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(notice, findsOneWidget);
  });

  for (final MapEntry(key: device, value: size) in sizes.entries) {
    testWidgets(
      'the club reads photos, settles a category and registers on $device',
      (tester) async {
        final repository = await open(tester, size);
        await readList(tester);

        expect(repository.sentFiles.single, ['lista1.jpg', 'lista2.jpg']);
        expect(
          find.text('2 participants · 1 with errors · 1 to check'),
          findsOneWidget,
        );
        expect(find.text('It says 7-8, but by age it is 9-10'), findsOneWidget);
        expect(find.textContaining('No category'), findsNothing);
        expect(
          find.text('Check the last name: it was not read with certainty'),
          findsOneWidget,
        );
        final register = find.widgetWithText(
          FilledButton,
          'Register 2 participants',
        );
        expect(tester.widget<FilledButton>(register).onPressed, isNull);

        await tester.tap(find.text('Use 7-8'));
        await tester.pumpAndSettle();
        expect(repository.checked.single[1].categoryId, 'c78');
        expect(tester.widget<FilledButton>(register).onPressed, isNotNull);

        await tester.tap(register);
        await tester.pumpAndSettle();
        expect(repository.registered.single, hasLength(2));
        expect(find.text('2 participants registered'), findsOneWidget);
        expect(find.byType(ImportScreen), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('choosing the age category drops the written one', (
    tester,
  ) async {
    final repository = await open(tester, sizes['tablet']!);
    await readList(tester);

    await tester.tap(find.text('Use 9-10'));
    await tester.pumpAndSettle();

    final settled = repository.checked.single[1];
    expect(settled.categoryId, isNull);
    expect(settled.categoryText, isNull);
  });

  testWidgets('a refused registration keeps the list and marks why', (
    tester,
  ) async {
    final repository = await open(tester, sizes['tablet']!);
    await readList(tester);
    await tester.tap(find.byTooltip('Remove from the list').last);
    await tester.pumpAndSettle();
    repository.refuseRegister = true;

    await tester.tap(
      find.widgetWithText(FilledButton, 'Register 1 participant'),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Nobody was registered: check the marked rows.'),
      findsOneWidget,
    );
    expect(find.text('Already registered in the event'), findsOneWidget);
    expect(find.byType(ImportScreen), findsOneWidget);
  });

  testWidgets('the template downloads as a CSV', (tester) async {
    final saved = <String>[];
    await open(tester, sizes['tablet']!, saved: saved);

    await tester.tap(find.text('Download template'));
    await tester.pumpAndSettle();

    expect(saved, ['plantilla_alumnos.csv']);
  });
}
