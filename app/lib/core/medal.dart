import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';

/// Gold, silver and bronze, the same in every ranking. Medal metals, not a competitor's red or blue.
Color? medalColor(int place) => switch (place) {
  1 => const Color(0xFFC9A227),
  2 => const Color(0xFF9EA4AA),
  3 => const Color(0xFFB0703C),
  _ => null,
};

String medalName(AppLocalizations l10n, int place) => switch (place) {
  1 => l10n.medalGold,
  2 => l10n.medalSilver,
  _ => l10n.medalBronze,
};

/// A place in a ranking: a gold, silver or bronze disc for the podium, a plain one after it. The
/// medal is also said in words (tooltip and screen readers), never only by colour.
class PlaceBadge extends StatelessWidget {
  const PlaceBadge({super.key, required this.place});

  final int place;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final metal = medalColor(place);
    final badge = CircleAvatar(
      backgroundColor: metal,
      foregroundColor: metal == null ? null : Colors.black,
      child: Text(
        '$place',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
    if (metal == null) return badge;
    final name = medalName(l10n, place);
    return Tooltip(
      message: name,
      child: Semantics(label: name, child: badge),
    );
  }
}

/// The medal on its own, as an icon: for rows that already show the place.
class MedalIcon extends StatelessWidget {
  const MedalIcon({super.key, required this.medal});

  final int medal;

  @override
  Widget build(BuildContext context) {
    final name = medalName(AppLocalizations.of(context), medal);
    return Tooltip(
      message: name,
      child: Semantics(
        label: name,
        child: Icon(Icons.military_tech, color: medalColor(medal)),
      ),
    );
  }
}
