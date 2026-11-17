import 'package:brackety_admin/features/debug/data/debug_api.dart';
import 'package:brackety_admin/features/debug/state/debug_providers.dart';
import 'package:brackety_admin/features/debug/ui/debug_screen.dart';
import 'package:brackety_admin/l10n/gen/app_localizations.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

class FakeDebugApi implements DebugApi {
  final calls = <String>[];

  @override
  Future<List<Scenario>> scenarios() async => const [
    Scenario(name: 'empty', description: 'Nothing'),
    Scenario(
      name: 'yoseikan-f1',
      description: 'Phase 1 with fictitious students',
    ),
  ];

  @override
  Future<DebugStatus> load(String name, {DateTime? today}) async {
    calls.add('load $name');
    return DebugStatus(
      scenario: name,
      today: DateTime(2027, 1, 24),
      simulated: false,
    );
  }

  @override
  Future<DebugStatus> moveClock(DateTime? today) async {
    calls.add('clock $today');
    return DebugStatus(
      today: today ?? DateTime(2027, 1, 24),
      simulated: today != null,
    );
  }

  @override
  Future<List<Snapshot>> snapshots() async => [
    Snapshot(
      name: 'antes_f2',
      savedAt: DateTime.utc(2027, 1, 20, 10),
      scenario: 'yoseikan-f1',
    ),
  ];

  @override
  Future<void> save(String name) async => calls.add('save $name');

  @override
  Future<DebugStatus> restore(String name) async {
    calls.add('restore $name');
    return DebugStatus(
      scenario: 'yoseikan-f1',
      today: DateTime(2027, 1, 24),
      simulated: false,
    );
  }

  @override
  Future<void> delete(String name) async => calls.add('delete $name');
}

void main() {
  for (final MapEntry(key: device, value: size) in screenSizes.entries) {
    testWidgets(
      'the superadmin loads a scenario and restores a copy on $device',
      (tester) async {
        useSize(tester, size);
        final api = FakeDebugApi();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              debugApiProvider.overrideWithValue(api),
              debugStatusProvider.overrideWith(
                (ref) async => DebugStatus(
                  scenario: 'yoseikan-f1',
                  today: DateTime(2027, 1, 24),
                  simulated: true,
                ),
              ),
            ],
            child: MaterialApp(
              locale: const Locale('en'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...coreLocalizationsDelegates,
              ],
              builder: (_, child) =>
                  ToastHost(child: DebugBanner(child: child!)),
              home: const Scaffold(body: DebugScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Never taken for production.
        expect(
          find.text('DEBUG · yoseikan-f1 · 1/24/2027 (simulated)'),
          findsOneWidget,
        );
        expect(find.text('Phase 1 with fictitious students'), findsOneWidget);

        await tester.tap(find.widgetWithText(FilledButton, 'Load').last);
        await tester.pumpAndSettle();
        final confirm = find.widgetWithText(FilledButton, 'Load').last;
        expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
        await tester.enterText(find.byType(TextField).last, 'yoseikan-f1');
        await tester.pump();
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        expect(api.calls, ['load yoseikan-f1']);

        await tester.scrollUntilVisible(
          find.text('antes_f2'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.widgetWithText(TextButton, 'Restore'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Restore'));
        await tester.pumpAndSettle();
        expect(api.calls, ['load yoseikan-f1', 'restore antes_f2']);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
