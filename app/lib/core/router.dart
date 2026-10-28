import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/ui/home_screen.dart';
import '../l10n/gen/app_localizations.dart';

const _tabs = ['/', '/connection'];

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            _AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
          GoRoute(
            path: '/connection',
            builder: (_, _) => const ConnectionScreen(),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class _AppShell extends StatelessWidget {
  const _AppShell({required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AdaptiveScaffold(
      title: l10n.appTitle,
      destinations: [
        AdaptiveDestination(icon: Icons.home_outlined, label: l10n.navHome),
        AdaptiveDestination(
          icon: Icons.dns_outlined,
          label: l10n.navConnection,
        ),
      ],
      selectedIndex: _tabs.indexOf(location).clamp(0, _tabs.length - 1),
      onSelected: (index) => context.go(_tabs[index]),
      body: child,
    );
  }
}
