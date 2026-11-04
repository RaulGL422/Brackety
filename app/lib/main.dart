import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';

void main() {
  ensureApiConfigured();
  registerFontLicenses();
  // URLs without '#', so the email links (/verify-email?token=…) open the right screen.
  usePathUrlStrategy();
  runApp(const ProviderScope(child: BracketyApp()));
}
