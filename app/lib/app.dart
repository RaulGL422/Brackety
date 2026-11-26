import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'features/appearance/state/device_prefs_provider.dart';
import 'features/appearance/state/theme_mode_provider.dart';
import 'features/auth/state/account_controller.dart';
import 'features/auth/ui/verification_banner.dart';
import 'features/offline/state/leave_guard.dart';
import 'features/offline/state/offline_sync.dart';
import 'l10n/gen/app_localizations.dart';

class BracketyApp extends ConsumerWidget {
  const BracketyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // From the start: a queue left from the last run (or the last page load) goes out, and
    // sign-out clears it. While it has actions, the web asks before leaving the page.
    ref.listen(
      offlineSyncProvider.select((s) => s.pendingCount > 0),
      (_, unsent) => guardLeaving(unsent),
    );
    final moreContrast = ref.watch(
      devicePrefsProvider.select((p) => p.moreContrast),
    );
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: lightTheme(moreContrast: moreContrast),
      darkTheme: darkTheme(moreContrast: moreContrast),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      locale: ref.watch(appLocaleProvider),
      // A new release blocks the app until it reloads, but never with actions still unsent.
      builder: (_, child) => Consumer(
        builder: (_, ref, _) => UpdateGate(
          hold: ref.watch(
            offlineSyncProvider.select((s) => s.pendingCount > 0),
          ),
          child: _TextSize(
            child: ToastHost(
              child: DebugBanner(child: VerificationBanner(child: child!)),
            ),
          ),
        ),
      ),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...coreLocalizationsDelegates,
      ],
    );
  }
}

/// The size chosen in «Ajustes de la app» over the device's own; none chosen, the device's.
class _TextSize extends ConsumerWidget {
  const _TextSize({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = ref.watch(devicePrefsProvider.select((p) => p.textScale));
    if (scale == null) return child;
    return MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child,
    );
  }
}
