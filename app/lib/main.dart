import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  ensureApiConfigured();
  registerFontLicenses();
  runApp(const ProviderScope(child: BracketyApp()));
}
