import 'package:flutter/services.dart';

/// Widget tests draw with a block font by default; layout checks (does it fit on one line?)
/// need the real fonts from brackety_core.
Future<void> loadRealFonts() async {
  const base = 'packages/brackety_core/assets/fonts';
  final body = FontLoader('packages/brackety_core/ZenKakuGothicNew');
  for (final file in ['Regular', 'Medium', 'Bold']) {
    body.addFont(rootBundle.load('$base/ZenKakuGothicNew-$file.ttf'));
  }
  final display = FontLoader('packages/brackety_core/SairaCondensed');
  for (final file in ['SemiBold', 'Bold', 'ExtraBold']) {
    display.addFont(rootBundle.load('$base/SairaCondensed-$file.ttf'));
  }
  await Future.wait([body.load(), display.load()]);
}
