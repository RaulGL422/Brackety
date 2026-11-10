import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../mat/ui/fighter_text.dart';
import '../data/match_view.dart';
import 'corner_panel.dart';

/// Both fighters, one row each in their corner's colour; with [showWinner] the winner is
/// marked (or the draw said).
class FinalScore extends StatelessWidget {
  const FinalScore({super.key, required this.view, this.showWinner = true});

  final MatchView view;
  final bool showWinner;

  @override
  Widget build(BuildContext context) {
    final winner = showWinner ? view.winner : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.s,
      children: [
        for (final side in Side.values)
          _ScoreRow(
            side: side,
            corner: view.corner(side),
            winner: winner == side,
          ),
        if (showWinner && winner == null)
          Text(
            AppLocalizations.of(context).draw,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.side,
    required this.corner,
    required this.winner,
  });

  final Side side;
  final Corner corner;
  final bool winner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final color = cornerColor(side);
    final style = TextStyle(color: color.onColor);
    return Material(
      color: color.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
        // The winner's row stands out without relying on its colour.
        side: winner
            ? BorderSide(
                color: Theme.of(context).colorScheme.onSurface,
                width: AppSpacing.xs,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Row(
          spacing: AppSpacing.m,
          children: [
            if (winner) Icon(Icons.emoji_events, color: color.onColor),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    winner
                        ? '${cornerName(l10n, side)} · ${l10n.winner}'
                        : cornerName(l10n, side),
                    style: text.labelLarge?.merge(style),
                  ),
                  Text(
                    corner.title(l10n),
                    style: text.titleLarge?.merge(style),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text('${corner.points}', style: text.displaySmall?.merge(style)),
          ],
        ),
      ),
    );
  }
}
