import 'package:brackety_core/brackety_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import 'auth_app.dart';

// «Cambios (debug)»: what each debug build brings, only against the debug server.
void main() {
  testWidgets('against the debug server the account menu opens the changes', (
    tester,
  ) async {
    await pumpAuthApp(
      tester,
      FakeAuthApi(signedIn: true),
      debug: DebugStatus(today: DateTime(2026, 11, 25), simulated: false),
      overrides: [
        changelogProvider.overrideWith(
          (ref) async => parseChangelog(
            '## Sin publicar (en debug)\n### Nuevo\n- Cambios en debug (#201).\n',
          ),
        ),
      ],
    );

    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Changes (debug)'));
    await tester.pumpAndSettle();

    expect(find.text('Cambios en debug (#201).'), findsOneWidget);
  });

  testWidgets('elsewhere the menu does not offer it', (tester) async {
    await pumpAuthApp(tester, FakeAuthApi(signedIn: true));

    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();

    expect(find.text('Changes (debug)'), findsNothing);
  });
}
