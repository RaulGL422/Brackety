import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/state/admin_session.dart';
import '../features/auth/ui/login_screen.dart';
import '../features/auth/ui/logout_button.dart';
import '../features/dashboard/ui/dashboard_screen.dart';
import '../features/design_system/ui/design_system_screen.dart';
import '../features/events/ui/events_screen.dart';
import '../features/locks/ui/locks_screen.dart';
import '../features/organizers/ui/organizers_screen.dart';
import '../l10n/gen/app_localizations.dart';

// They call no admin endpoint, so they open without a session.
const _anySession = {'/connection', '/design-system'};

final routerProvider = Provider<GoRouter>((ref) {
  // The router asks for the session on every navigation; this tells it when to ask again.
  final sessionChanged = ValueNotifier(0);
  ref.listen(
    adminSessionProvider.select((s) => s.signedIn),
    (_, _) => sessionChanged.value++,
  );

  final router = adaptiveShellRouter(
    title: (context) => AppLocalizations.of(context).appTitle,
    refreshListenable: sessionChanged,
    redirect: (context, state) {
      final at = state.matchedLocation;
      if (_anySession.contains(at)) return null;
      final signedIn = ref.read(adminSessionProvider).signedIn;
      if (!signedIn) return at == '/login' ? null : '/login';
      return at == '/login' ? '/' : null;
    },
    routes: [GoRoute(path: '/login', builder: (_, _) => const LoginScreen())],
    actions: (_) => const [LogoutButton()],
    tabs: [
      AdaptiveTab(
        path: '/',
        icon: Icons.dashboard_outlined,
        label: (context) => AppLocalizations.of(context).navDashboard,
        builder: (_) => const DashboardScreen(),
      ),
      AdaptiveTab(
        path: '/events',
        icon: Icons.event_note_outlined,
        label: (context) => AppLocalizations.of(context).navEvents,
        builder: (_) => const EventsScreen(),
      ),
      AdaptiveTab(
        path: '/locks',
        icon: Icons.lock_clock_outlined,
        label: (context) => AppLocalizations.of(context).navLocks,
        builder: (_) => const LocksScreen(),
      ),
      AdaptiveTab(
        path: '/organizers',
        icon: Icons.verified_user_outlined,
        label: (context) => AppLocalizations.of(context).navOrganizers,
        builder: (_) => const OrganizersScreen(),
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
  ref.onDispose(() {
    router.dispose();
    sessionChanged.dispose();
  });
  return router;
});
