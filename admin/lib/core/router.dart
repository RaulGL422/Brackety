import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/ui/dashboard_screen.dart';
import '../features/design_system/ui/design_system_screen.dart';
import '../l10n/gen/app_localizations.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = adaptiveShellRouter(
    title: (context) => AppLocalizations.of(context).appTitle,
    tabs: [
      AdaptiveTab(
        path: '/',
        icon: Icons.dashboard_outlined,
        label: (context) => AppLocalizations.of(context).navDashboard,
        builder: (_) => const DashboardScreen(),
      ),
      AdaptiveTab(
        path: '/connection',
        icon: Icons.dns_outlined,
        label: (context) => AppLocalizations.of(context).navConnection,
        builder: (_) => const ConnectionScreen(),
      ),
      if (kDebugMode)
        AdaptiveTab(
          path: '/design-system',
          icon: Icons.palette_outlined,
          label: (context) => AppLocalizations.of(context).navDesignSystem,
          builder: (_) => const DesignSystemScreen(),
        ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
