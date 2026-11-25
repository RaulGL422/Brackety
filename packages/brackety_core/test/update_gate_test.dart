import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The server says there is (or is not) a new release, without asking it.
class _Answered extends UpdateCheck {
  _Answered(this.available);

  final bool available;

  @override
  bool build() => available;
}

void main() {
  ServerInfo server(String version, [String commit = '']) => ServerInfo(
    name: 'brackety',
    today: DateTime(2026, 11, 25),
    version: version,
    commit: commit,
  );

  group('a new release', () {
    const build = (version: '0.8.2-dev.89', commit: 'f1118ca');

    test('is another version or another commit', () {
      expect(
        UpdateCheck.differs(build, server('0.8.2-dev.90', 'b10a487')),
        isTrue,
      );
      expect(
        UpdateCheck.differs(build, server('0.8.2-dev.89', 'b10a487')),
        isTrue,
      );
      expect(
        UpdateCheck.differs(build, server('0.8.2-dev.89', 'f1118ca')),
        isFalse,
      );
    });

    test('is not guessed when a side does not say', () {
      expect(UpdateCheck.differs(build, server('')), isFalse);
      expect(UpdateCheck.differs(build, server('0.8.2-dev.89')), isFalse);
      expect(
        UpdateCheck.differs((
          version: '0.8.2',
          commit: '',
        ), server('0.8.2', 'x')),
        isFalse,
      );
    });
  });

  test('a build without a version (local, Android) never asks', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(updateAvailableProvider), isFalse);
  });

  Future<List<String>> pump(
    WidgetTester tester, {
    required bool available,
    bool hold = false,
    Size size = const Size(360, 800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final reloads = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          updateAvailableProvider.overrideWith(() => _Answered(available)),
        ],
        child: MaterialApp(
          theme: lightTheme(),
          localizationsDelegates: coreLocalizationsDelegates,
          supportedLocales: const [Locale('es'), Locale('en')],
          locale: const Locale('en'),
          builder: (_, child) => UpdateGate(
            hold: hold,
            reload: () => reloads.add('reload'),
            child: child!,
          ),
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Behind'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return reloads;
  }

  for (final (device, size) in [
    ('phone', const Size(360, 800)),
    ('tablet', const Size(800, 1280)),
    ('desktop', const Size(1440, 900)),
  ]) {
    testWidgets('a new release leaves only the update on $device', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final reloads = await pump(tester, available: true, size: size);

      expect(find.text('A new version of Brackety is out'), findsOneWidget);
      await tester.tap(find.text('Behind'), warnIfMissed: false);
      expect(reloads, isEmpty);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));

      await tester.tap(find.text('Update'));
      expect(reloads, ['reload']);
      handle.dispose();
    });
  }

  testWidgets('with actions unsent it only says so and lets the work go on', (
    tester,
  ) async {
    final reloads = await pump(tester, available: true, hold: true);

    expect(
      find.textContaining('as soon as the pending actions'),
      findsOneWidget,
    );
    expect(find.text('Update'), findsNothing);
    await tester.tap(find.text('Behind'));
    expect(reloads, isEmpty);
  });

  testWidgets('without a new release nothing shows', (tester) async {
    await pump(tester, available: false);

    expect(find.text('A new version of Brackety is out'), findsNothing);
    expect(find.text('Behind'), findsOneWidget);
  });

  testWidgets('text at 200 % fits on a phone', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(tester, available: true);

    expect(find.text('Update'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
