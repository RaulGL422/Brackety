import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'features/appearance/state/theme_mode_provider.dart';
import 'features/auth/state/account_controller.dart';
import 'features/auth/ui/verification_banner.dart';
import 'features/offline/state/offline_sync.dart';
import 'l10n/gen/app_localizations.dart';

class BracketyApp extends ConsumerWidget {
  const BracketyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // From the start: a queue left from the last run (or the last page load) goes out, and
    // sign-out clears it.
    ref.listen(offlineSyncProvider, (_, _) {});
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      locale: ref.watch(appLocaleProvider),
      builder: (_, child) =>
          ToastHost(child: VerificationBanner(child: child!)),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...coreLocalizationsDelegates,
      ],
    );
  }
}
