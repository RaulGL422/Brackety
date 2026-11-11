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
    this.actions,
    this.leading,
    this.leadingWidth,
  });

  static const maxContentWidth = 1200.0;

  // NavigationBar caps its label text scale at this (Flutter's _kMaxLabelTextScaleFactor).
  static const _navigationBarMaxTextScale = 1.3;

  final String title;
  final List<AdaptiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final double? leadingWidth;

  /// Whether every bottom-bar label fits on one line in its share of the width. If one does
  /// not, the bar shows icons only (the label stays as tooltip and for screen readers): a
  /// wrapped label breaks the bar, and showing only the selected one does not help because it
  /// gets the same width. Measured like [NavigationBar] draws them (its text scale is capped).
  bool _labelsFit(BuildContext context) {
    final theme = Theme.of(context);
    final style =
        theme.navigationBarTheme.labelTextStyle?.resolve(const {
          WidgetState.selected,
        }) ??
        theme.textTheme.labelMedium;
    final room = MediaQuery.sizeOf(context).width / destinations.length;
    final scaler = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: _navigationBarMaxTextScale);
    return destinations.every((d) {
      final painter = TextPainter(
        text: TextSpan(text: d.label, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width <= room;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = WindowSize.of(context);
    final content = _ConstrainedBody(child: body);

    if (size == WindowSize.compact) {
      return Scaffold(
        appBar: AppBar(
          leading: leading,
          leadingWidth: leadingWidth,
          title: Text(title),
          actions: actions,
        ),
        body: content,
        bottomNavigationBar: NavigationBar(
          labelBehavior: _labelsFit(context)
              ? NavigationDestinationLabelBehavior.alwaysShow
              : NavigationDestinationLabelBehavior.alwaysHide,
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
      appBar: AppBar(
        leading: leading,
        leadingWidth: leadingWidth,
        title: Text(title),
        actions: actions,
      ),
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
