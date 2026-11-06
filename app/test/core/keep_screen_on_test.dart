import 'package:brackety/core/keep_screen_on.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the screen stays on until the last screen that asks closes', (
    tester,
  ) async {
    final calls = <bool>[];
    final original = KeepScreenOn.toggle;
    KeepScreenOn.toggle = calls.add;
    addTearDown(() => KeepScreenOn.toggle = original);

    // The board, then the scoreboard over it.
    await tester.pumpWidget(
      const Column(children: [KeepScreenOn(child: SizedBox())]),
    );
    await tester.pumpWidget(
      const Column(
        children: [
          KeepScreenOn(child: SizedBox()),
          KeepScreenOn(child: SizedBox()),
        ],
      ),
    );
    expect(calls, [true]);

    // Back to the board: still on.
    await tester.pumpWidget(
      const Column(children: [KeepScreenOn(child: SizedBox())]),
    );
    expect(calls, [true]);

    await tester.pumpWidget(const SizedBox());
    expect(calls, [true, false]);
  });
}
