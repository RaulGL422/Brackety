import 'package:brackety/features/auth/state/session_controller.dart';
import 'package:brackety/features/offline/data/offline_op.dart';
import 'package:brackety/features/offline/state/offline_sync.dart';
import 'package:brackety/features/offline/ui/confirm_sign_out.dart';
import 'package:brackety/features/scoreboard/data/match_view.dart';
import 'package:brackety/l10n/gen/app_localizations.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/offline_fakes.dart';

void main() {
  const sizes = {
    'phone': Size(360, 800),
    'tablet': Size(800, 1280),
    'desktop': Size(1440, 900),
  };

  late MemoryOfflineStore store;
  late FakeAuthApi auth;

  setUp(() {
    store = MemoryOfflineStore();
    auth = FakeAuthApi(signedIn: true);
  });

  void queued(int count) => store.docs['queue'] = {
    'ops': [
      for (var i = 0; i < count; i++)
        OfflineOp(
          opId: 'op$i',
          matchId: 'm1',
          action: MatchAction.point,
          side: Side.red,
          at: t0,
          knownEvents: i,
        ).toJson(),
    ],
  };

  Future<ProviderContainer> pump(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final clock = TestClock();
    final server = FakeMatchServer([serverMatch('m1')], clock)..down = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: offlineOverrides(
          store: store,
          clock: clock,
          repository: server,
          auth: auth,
        ),
        child: MaterialApp(
          theme: lightTheme(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...coreLocalizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: TextButton(
                onPressed: () => confirmSignOut(context, ref),
                child: const Text('out'),
              ),
            ),
          ),
        ),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.text('out')),
    );
    container.read(sessionProvider);
    // Alive and loaded, as the app keeps it from the start.
    container.listen(offlineSyncProvider, (_, _) {});
    for (var i = 0; i < 3; i++) {
      await tester.pump();
    }
    return container;
  }

  for (final MapEntry(key: name, value: size) in sizes.entries) {
    testWidgets('signing out with actions not sent asks first on $name', (
      tester,
    ) async {
      queued(2);
      final container = await pump(tester, size);

      await tester.tap(find.text('out'));
      await tester.pumpAndSettle();
      expect(
        find.text('Tienes 2 acciones sin enviar; si sales se perderán.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(container.read(sessionProvider).status, SessionStatus.signedIn);

      await tester.tap(find.text('out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salir'));
      await tester.pumpAndSettle();
      expect(container.read(sessionProvider).status, SessionStatus.signedOut);
      expect(store.docs, isEmpty);
    });
  }

  testWidgets('signing out with nothing waiting does not ask', (tester) async {
    final container = await pump(tester, sizes['phone']!);

    await tester.tap(find.text('out'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(container.read(sessionProvider).status, SessionStatus.signedOut);
  });
}
