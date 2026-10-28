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

/// Router whose top-level tabs share one [AdaptiveScaffold].
GoRouter adaptiveShellRouter({
  required String Function(BuildContext context) title,
  required List<AdaptiveTab> tabs,
}) {
  return GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          final index = tabs.indexWhere((t) => t.path == state.uri.path);
          return AdaptiveScaffold(
            title: title(context),
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
