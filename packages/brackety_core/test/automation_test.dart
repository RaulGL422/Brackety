import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // testWidgets turns semantics on by default; these tests need them off at the start.
  testWidgets('semantics stay off when automation is not enabled', (_) async {
    enableSemanticsForAutomation(enabled: false);

    expect(SemanticsBinding.instance.semanticsEnabled, isFalse);
  }, semanticsEnabled: false);

  testWidgets('semantics turn on when automation is enabled', (_) async {
    enableSemanticsForAutomation(enabled: true);
    enableSemanticsForAutomation(enabled: true);

    expect(SemanticsBinding.instance.semanticsEnabled, isTrue);
    disableSemanticsForAutomation();
    expect(SemanticsBinding.instance.semanticsEnabled, isFalse);
  }, semanticsEnabled: false);
}
