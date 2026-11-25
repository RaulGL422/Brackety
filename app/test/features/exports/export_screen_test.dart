import 'package:brackety/core/download/file_download.dart';
import 'package:brackety/features/exports/data/export_models.dart';
import 'package:brackety/features/exports/data/export_repository.dart';
import 'package:brackety/features/exports/state/export_controller.dart';
import 'package:brackety/features/exports/ui/export_screen.dart';
import 'package:brackety/l10n/gen/app_localizations.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers like the server: the preview has the chosen columns, titled as asked.
class _FakeExports implements ExportRepository {
  final downloads = <Map<String, dynamic>>[];

  static const sheetList = [
    ExportSheet(
      key: 'participants',
      title: 'Participants',
      fields: [
        ExportField(key: 'firstName', title: 'First name'),
        ExportField(key: 'lastName', title: 'Last name'),
        ExportField(
          key: 'birthDate',
          title: 'Date of birth',
          kind: FieldKind.date,
          sensitivity: Sensitivity.personal,
        ),
        ExportField(
          key: 'weightKg',
          title: 'Weight (kg)',
          kind: FieldKind.decimal,
          sensitivity: Sensitivity.personal,
        ),
        ExportField(key: 'category', title: 'Category'),
      ],
    ),
    ExportSheet(
      key: 'matches',
      title: 'Matches',
      fields: [
        ExportField(key: 'group', title: 'Group', kind: FieldKind.number),
        ExportField(key: 'red', title: 'Red'),
      ],
    ),
  ];

  @override
  Future<List<ExportSheet>> sheets(String eventId, String language) async =>
      sheetList;

  @override
  Future<ExportPreview> preview(String eventId, ExportDraft draft) async {
    final sheet = sheetList.firstWhere((s) => s.key == draft.sheet);
    return ExportPreview(
      headers: [
        for (final c in draft.columns) draft.titles[c] ?? sheet.field(c)!.title,
      ],
      rows: [
        for (final name in ['Ana', 'Bea'])
          [for (final c in draft.columns) c == 'firstName' ? name : '–'],
      ],
      totalRows: 37,
    );
  }

  @override
  Future<({String name, List<int> bytes, String mimeType})> download(
    String eventId,
    ExportDraft draft,
  ) async {
    downloads.add(draft.toJson());
    return (
      name: 'liga_participantes.${draft.format.name}',
      bytes: [1, 2, 3],
      mimeType: draft.format.mimeType,
    );
  }
}

void main() {
  const sizes = {
    'phone': Size(360, 800),
    'tablet': Size(800, 1280),
    'desktop': Size(1440, 900),
  };

  Future<({_FakeExports exports, List<String> saved})> pump(
    WidgetTester tester,
    Size size, {
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final exports = _FakeExports();
    final saved = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exportRepositoryProvider.overrideWithValue(exports),
          saveFileProvider.overrideWithValue(
            (name, bytes, mimeType) async => saved.add('$name $mimeType'),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: ToastHost(child: child!),
          ),
          theme: lightTheme(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...coreLocalizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ExportScreen(eventId: 'e1'),
        ),
      ),
    );
    await settle(tester);
    return (exports: exports, saved: saved);
  }

  for (final MapEntry(key: device, value: size) in sizes.entries) {
    testWidgets('starts with the first sheet and its non-personal columns on '
        '$device', (tester) async {
      await pump(tester, size);

      if (device == 'desktop') {
        expect(find.text('Which data'), findsOneWidget);
        expect(find.text('Preview'), findsOneWidget);
        expect(find.text('2 of 37 rows'), findsOneWidget);
      } else {
        expect(find.text('Step 1 of 5'), findsOneWidget);
      }
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      expect(tester.takeException(), isNull);
    });

    testWidgets('text at 200 % fits on $device', (tester) async {
      await pump(tester, size, textScale: 2);
      expect(tester.takeException(), isNull);
      if (device != 'desktop') {
        await tester.tap(find.text('Next'));
        await settle(tester);
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('a column goes down with its button and the preview follows', (
    tester,
  ) async {
    await pump(tester, sizes['desktop']!);
    expect(headers(tester), ['First name', 'Last name', 'Category']);

    await tester.tap(find.byTooltip('Move First name down'));
    await settle(tester);

    expect(headers(tester), ['Last name', 'First name', 'Category']);
  });

  testWidgets('a column takes a title of its own', (tester) async {
    await pump(tester, sizes['desktop']!);

    await tester.tap(find.byTooltip('Change the title of Category'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Grupo de edad');
    await tester.tap(find.text('Save'));
    await settle(tester);

    expect(headers(tester), ['First name', 'Last name', 'Grupo de edad']);
  });

  testWidgets('personal data asks before downloading and says which', (
    tester,
  ) async {
    final (:exports, :saved) = await pump(tester, sizes['desktop']!);

    await tester.tap(find.text('Add column'));
    await settle(tester);
    await tester.tap(find.text('Date of birth'));
    await settle(tester);
    expect(find.text('Personal data'), findsOneWidget);

    await tester.tap(find.text('Download'));
    await settle(tester);
    expect(find.text('It has personal data'), findsOneWidget);
    expect(find.textContaining('It includes Date of birth.'), findsOneWidget);
    await tester.tap(find.text('Download').last);
    await settle(tester);

    expect(exports.downloads.single['columns'], [
      'firstName',
      'lastName',
      'category',
      'birthDate',
    ]);
    expect(saved, ['liga_participantes.csv text/csv']);
  });

  testWidgets('on a phone it goes step by step and downloads at the end', (
    tester,
  ) async {
    final (:exports, :saved) = await pump(tester, sizes['phone']!);

    for (final step in ['Columns', 'Filter rows', 'Format', 'Preview']) {
      await tester.tap(find.text('Next'));
      await settle(tester);
      expect(find.text(step), findsWidgets);
    }
    expect(find.text('Next'), findsNothing);
    expect(find.text('2 of 37 rows'), findsOneWidget);

    await tester.tap(find.text('Download'));
    await settle(tester);

    expect(exports.downloads, hasLength(1));
    expect(saved, hasLength(1));
  });

  testWidgets('a PDF takes its title and page, a split says what it does', (
    tester,
  ) async {
    final (:exports, :saved) = await pump(tester, sizes['desktop']!);

    // The settings are a lazy list: scroll until the format is built, then bring it into view.
    await tester.scrollUntilVisible(
      find.text('PDF'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('PDF'));
    await settle(tester);
    await tester.tap(find.text('PDF'));
    await settle(tester);
    await tester.ensureVisible(find.text('Landscape'));
    await settle(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'PDF title'),
      'Lista para la mesa',
    );
    await tester.tap(find.text('Landscape'));
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String?>));
    await settle(tester);
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await settle(tester);
    await tester.tap(find.text('Category').last);
    await settle(tester);
    expect(find.text('One page per value.'), findsOneWidget);

    await tester.tap(find.text('Download'));
    await settle(tester);

    expect(exports.downloads.single, containsPair('format', 'pdf'));
    expect(
      exports.downloads.single,
      containsPair('title', 'Lista para la mesa'),
    );
    expect(exports.downloads.single, containsPair('landscape', true));
    expect(exports.downloads.single, containsPair('splitBy', 'category'));
    expect(saved, ['liga_participantes.pdf application/pdf']);
  });
}

/// Past the preview's wait.
Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(previewDelay);
  await tester.pumpAndSettle();
}

List<String> headers(WidgetTester tester) => [
  for (final column in tester.widget<DataTable>(find.byType(DataTable)).columns)
    ((column.label as ConstrainedBox).child! as Text).data!,
];
