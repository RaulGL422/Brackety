import 'package:brackety/features/control/control_repository.dart';
import 'package:brackety/features/control/mat_groups.dart';
import 'package:brackety/features/control/mat_groups_screen.dart';
import 'package:brackety/l10n/gen/app_localizations.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeControl extends ControlRepository {
  _FakeControl() : super(Dio());

  final moved = <String>[];

  @override
  Future<void> moveGroup(String eventId, String groupId, String matId) async =>
      moved.add('$groupId → $matId');
}

// GR-4: every mat's groups with who is in them, moved by dragging or with "Move to…".
void main() {
  const sizes = {
    'phone': Size(360, 800),
    'tablet': Size(800, 1280),
    'desktop': Size(1440, 900),
  };

  const mats = [
    MatGroups(
      matId: 'm1',
      number: 1,
      referee: 'Juan',
      groups: [
        GroupCard(
          id: 'g1',
          number: 1,
          categoryName: '4-6',
          members: [
            (name: 'Ana Prueba', ghost: false),
            (name: 'Bea Prueba', ghost: false),
            (name: 'Carla Prueba', ghost: true),
          ],
          played: 2,
          matches: 3,
        ),
        GroupCard(
          id: 'g2',
          number: 2,
          categoryName: '4-6',
          members: [
            (name: 'Dani Prueba', ghost: false),
            (name: 'Eva Prueba', ghost: false),
          ],
          played: 0,
          matches: 1,
          inProgress: true,
        ),
      ],
    ),
    MatGroups(matId: 'm2', number: 2, referee: 'Luis', finishedGroups: 1),
    MatGroups(matId: 'm3', number: 3, disabled: true),
  ];

  Future<_FakeControl> pump(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final control = _FakeControl();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          controlRepositoryProvider.overrideWithValue(control),
          matGroupsProvider.overrideWith((ref, eventId) async => mats),
        ],
        child: MaterialApp(
          builder: (_, child) => ToastHost(child: child!),
          theme: lightTheme(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...coreLocalizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MatGroupsScreen(eventId: 'e1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return control;
  }

  for (final MapEntry(key: device, value: size) in sizes.entries) {
    testWidgets('every mat shows its groups and who is in them on $device', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, size);

      expect(find.text('Mat 1'), findsOneWidget);
      expect(find.text('Juan'), findsOneWidget);
      // The number on ink and the category beside it; a screen reader hears both.
      expect(find.bySemanticsLabel('Group 1 · 4-6'), findsOneWidget);
      // One name per line, whole.
      expect(find.text('Ana Prueba'), findsOneWidget);
      expect(find.text('Bea Prueba'), findsOneWidget);
      expect(find.text('Carla Prueba (wildcard)'), findsOneWidget);
      expect(find.text('2 of 3 fought'), findsOneWidget);
      expect(find.text('1 finished'), findsOneWidget);
      // On a phone the mats go one under another: the last one is further down.
      await tester.scrollUntilVisible(
        find.text('Mat 3'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Mat 3'), findsOneWidget);
      expect(find.text('Disabled'), findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('a group dragged onto another mat moves there', (tester) async {
    final control = await pump(tester, sizes['tablet']!);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Ana Prueba')),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveTo(tester.getCenter(find.text('Mat 2')));
    await tester.pump();
    expect(find.text('Drop here to move it to mat 2'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(control.moved, ['g1 → m2']);
  });

  testWidgets('"Move to…" offers only the other mats in use', (tester) async {
    final control = await pump(tester, sizes['phone']!);

    await tester.tap(find.byTooltip('Move group 1'));
    await tester.pumpAndSettle();
    // Neither the disabled mat nor the one it is already on.
    expect(find.text('Mat 3 · No referee'), findsNothing);
    expect(find.text('Mat 1 · Juan'), findsNothing);
    await tester.tap(find.text('Mat 2 · Luis').last);
    await tester.pumpAndSettle();

    expect(control.moved, ['g1 → m2']);
  });

  testWidgets('a group fighting now cannot move', (tester) async {
    await pump(tester, sizes['tablet']!);

    // No "Move to…" to tap, and an ink band that says why.
    expect(find.byTooltip('Move group 2'), findsNothing);
    expect(find.text('Fighting: it cannot move'), findsOneWidget);
  });

  testWidgets('the board fits a phone with text at 200 %', (tester) async {
    await pump(tester, sizes['phone']!);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
