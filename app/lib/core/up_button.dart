import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/gen/app_localizations.dart';

/// The way back, always visible and saying where it goes ("‹ Tapiz 1"). On the web a reload
/// or a shared link opens a screen with nothing behind it: then it goes to [fallback] instead
/// of disappearing, so nobody is left without a way out.
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

  /// The AppBar room for the label: wide enough to read it, never more than a third of a phone.
  static double leadingWidth(BuildContext context) =>
      (MediaQuery.sizeOf(context).width * 0.4).clamp(96, 200);

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
    final theme = Theme.of(context);
    // Inside an AppBar this is its foreground: also right on the dark band of the mat.
    final color = IconTheme.of(context).color ?? theme.colorScheme.onSurface;
    return Semantics(
      button: true,
      label: isPlace ? AppLocalizations.of(context).backTo(label) : label,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => go(context, fallback),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.only(left: 4, right: 8),
          child: Row(
            children: [
              Icon(Icons.chevron_left, size: 30, color: color),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
