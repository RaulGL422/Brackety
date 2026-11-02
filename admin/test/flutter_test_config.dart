import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'support/real_fonts.dart';

/// Every admin test draws with the real fonts, so "fits on one line" checks mean what they say.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadRealFonts();
  await testMain();
}
