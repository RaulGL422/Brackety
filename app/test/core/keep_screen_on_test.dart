import 'package:brackety/core/keep_screen_on.dart';
import 'package:brackety/features/appearance/data/device_prefs.dart';
import 'package:brackety/features/appearance/state/device_prefs_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<bool> recordToggles() {
    final calls = <bool>[];
    final original = KeepScreenOn.toggle;
    KeepScreenOn.toggle = calls.add;
    addTearDown(() => KeepScreenOn.toggle = original);
    return calls;
  }

  Widget scope(Widget child, {bool keepScreenOn = true}) => ProviderScope(
    overrides: [
      savedDevicePrefsProvider.overrideWithValue(
        DevicePrefs(keepScreenOn: keepScreenOn),
      ),
    ],
    child: child,
  );

  testWidgets('the screen stays on until the last screen that asks closes', (
    tester,
  ) async {
    final calls = recordToggles();

    // The board, then the scoreboard over it.
    await tester.pumpWidget(
      scope(const Column(children: [KeepScreenOn(child: SizedBox())])),
    );
    await tester.pumpWidget(
      scope(
        const Column(
          children: [
            KeepScreenOn(child: SizedBox()),
            KeepScreenOn(child: SizedBox()),
          ],
        ),
      ),
    );
    expect(calls, [true]);

    // Back to the board: still on.
    await tester.pumpWidget(
      scope(const Column(children: [KeepScreenOn(child: SizedBox())])),
    );
    expect(calls, [true]);

    await tester.pumpWidget(scope(const SizedBox()));
    expect(calls, [true, false]);
  });

  testWidgets('a device that turned it off keeps its usual timeout', (
    tester,
  ) async {
    final calls = recordToggles();

    await tester.pumpWidget(
      scope(const KeepScreenOn(child: SizedBox()), keepScreenOn: false),
    );
    await tester.pumpWidget(scope(const SizedBox(), keepScreenOn: false));

    expect(calls, isEmpty);
  });
}
