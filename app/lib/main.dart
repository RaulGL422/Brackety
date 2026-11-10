import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'features/appearance/data/theme_store.dart';
import 'features/appearance/state/theme_mode_provider.dart';
import 'features/server/data/server_store.dart';
import 'features/server/state/server_providers.dart';

Future<void> main() async {
  ensureApiConfigured();
  registerFontLicenses();
  // URLs without '#', so the email links (/verify-email?token=…) open the right screen.
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  enableSemanticsForAutomation();
  // Before the first request: the saved session belongs to the saved server.
  final savedServer = kIsWeb ? null : await const SecureServerStore().read();
  final savedTheme = await const SecureThemeStore().read();
  runApp(
    ProviderScope(
      overrides: [
        ...serverOverrides(savedServer),
        savedThemeModeProvider.overrideWithValue(savedTheme),
      ],
      child: const BracketyApp(),
    ),
  );
}
