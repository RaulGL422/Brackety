import 'package:flutter/services.dart';

/// Widget tests draw with a block font by default; layout checks (does it fit on one line?)
/// need the real Barlow from brackety_core.
Future<void> loadRealFonts() async {
  const base = 'packages/brackety_core/assets/fonts';
  final barlow = FontLoader('packages/brackety_core/Barlow');
  for (final file in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    barlow.addFont(rootBundle.load('$base/Barlow-$file.ttf'));
  }
  await barlow.load();
}
