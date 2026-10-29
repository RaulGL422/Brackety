import 'package:flutter/material.dart';

import 'window_size.dart';

class AdaptiveDestination {
  const AdaptiveDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Bottom bar on phones, navigation rail on tablets, extended rail on desktop (docs/07-diseno.md).
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.title,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.body,
  });

  static const maxContentWidth = 1200.0;

  final String title;
  final List<AdaptiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final size = WindowSize.of(context);
    final content = _ConstrainedBody(child: body);

    if (size == WindowSize.compact) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: content,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelected,
          destinations: [
            for (final d in destinations)
              NavigationDestination(icon: Icon(d.icon), label: d.label),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Row(
        children: [
          NavigationRail(
            extended: size == WindowSize.expanded,
            labelType: size == WindowSize.medium
                ? NavigationRailLabelType.all
                : NavigationRailLabelType.none,
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelected,
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _ConstrainedBody extends StatelessWidget {
  const _ConstrainedBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AdaptiveScaffold.maxContentWidth,
        ),
        child: child,
      ),
    );
  }
}
