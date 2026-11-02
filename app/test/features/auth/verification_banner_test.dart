import 'package:brackety/features/auth/ui/verification_banner.dart';
import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import 'auth_app.dart';

void main() {
  const text = 'Verify your email: some actions need it.';

  for (final MapEntry(key: device, value: size) in screenSizes.entries) {
    testWidgets('the banner goes edge to edge and wraps on $device', (
      tester,
    ) async {
      useSize(tester, size);
      await pumpAuthApp(
        tester,
        FakeAuthApi(signedIn: true)..emailVerified = false,
      );

      final banner = find.descendant(
        of: find.byType(VerificationBanner),
        matching: find.byType(Material),
      );
      expect(tester.getSize(banner.first).width, size.width);

      final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(tester.getRect(find.text(text)).right, lessThan(size.width));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('text and button use the warning on-colour', (tester) async {
    await pumpAuthApp(
      tester,
      FakeAuthApi(signedIn: true)..emailVerified = false,
    );
    final context = tester.element(find.text(text));
    final onWarning = BracketyColors.of(context).onWarningContainer;

    expect(DefaultTextStyle.of(context).style.color, onWarning);
    final button = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Resend email'),
    );
    final style = OutlinedButtonTheme.of(tester.element(find.byWidget(button)))
        .style!;
    expect(style.foregroundColor!.resolve({}), onWarning);
  });
}
