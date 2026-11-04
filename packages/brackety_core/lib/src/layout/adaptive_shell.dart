import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'adaptive_scaffold.dart';

class AdaptiveTab {
  const AdaptiveTab({
    required this.path,
    required this.icon,
    required this.label,
    required this.builder,
  });

  final String path;
  final IconData icon;
  final String Function(BuildContext context) label;
  final WidgetBuilder builder;
}

/// Router whose top-level tabs share one [AdaptiveScaffold]. [routes] live outside the shell
/// (a sign-in page, for example); [redirect], [refreshListenable] and [actions] go to the
/// router and the app bar as they are.
GoRouter adaptiveShellRouter({
  required String Function(BuildContext context) title,
  required List<AdaptiveTab> tabs,
  List<RouteBase> routes = const [],
  GoRouterRedirect? redirect,
  Listenable? refreshListenable,
  List<Widget> Function(BuildContext context)? actions,
}) {
  return GoRouter(
    redirect: redirect,
    refreshListenable: refreshListenable,
    routes: [
      ...routes,
      ShellRoute(
        builder: (context, state, child) {
          final index = tabs.indexWhere((t) => t.path == state.uri.path);
          return AdaptiveScaffold(
            title: title(context),
            actions: actions?.call(context),
            destinations: [
              for (final t in tabs)
                AdaptiveDestination(icon: t.icon, label: t.label(context)),
            ],
            selectedIndex: index < 0 ? 0 : index,
            onSelected: (i) => context.go(tabs[i].path),
            body: child,
          );
        },
        routes: [
          for (final t in tabs)
            GoRoute(path: t.path, builder: (context, _) => t.builder(context)),
        ],
      ),
    ],
  );
}
