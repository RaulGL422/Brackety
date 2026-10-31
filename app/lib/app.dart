import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'features/auth/ui/verification_banner.dart';
import 'l10n/gen/app_localizations.dart';

class BracketyApp extends ConsumerWidget {
  const BracketyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: lightTheme(),
      darkTheme: darkTheme(),
      routerConfig: ref.watch(routerProvider),
      builder: (_, child) => VerificationBanner(child: child!),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...coreLocalizationsDelegates,
      ],
    );
  }
}
