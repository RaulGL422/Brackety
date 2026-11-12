import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/gen/app_localizations.dart';

/// The way back, always visible: an arrow, with where it goes in its tooltip and for screen
/// readers ("Volver a Tapiz 1"). Only the arrow: a label took the room of the screen's title on
/// small phones. On the web a reload or a shared link opens a screen with nothing behind it: then
/// it goes to [fallback] instead of disappearing, so nobody is left without a way out.
class UpButton extends StatelessWidget {
  const UpButton({
    super.key,
    required this.label,
    required this.fallback,
    this.isPlace = true,
  });

  final String label;

  /// False when [label] is just "Volver": then it is read as is, not "Volver a Volver".
  final bool isPlace;
  final String fallback;

  /// The AppBar's usual room for one icon.
  static double leadingWidth(BuildContext context) => kToolbarHeight;

  static void go(BuildContext context, String fallback) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(fallback);
    }
  }

  @override
  Widget build(BuildContext context) {
    final where = isPlace ? AppLocalizations.of(context).backTo(label) : label;
    return IconButton(
      tooltip: where,
      icon: const Icon(Icons.arrow_back),
      onPressed: () => go(context, fallback),
    );
  }
}
