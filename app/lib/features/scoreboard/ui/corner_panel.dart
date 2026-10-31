import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/match_view.dart';

/// One fighter: big score, +1 and the warnings menu. Red and blue are fixed for this event.
class CornerPanel extends StatelessWidget {
  const CornerPanel({
    super.key,
    required this.side,
    required this.corner,
    required this.enabled,
    required this.onPoint,
    required this.onSanction,
  });

  final Side side;
  final Corner corner;
  final bool enabled;
  final VoidCallback onPoint;
  final void Function(MatchAction action) onSanction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final color = side == Side.red ? CompetitorColor.red : CompetitorColor.blue;
    final onColor = TextStyle(color: color.onColor);
    return Material(
      color: color.color,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              side == Side.red ? l10n.cornerRed : l10n.cornerBlue,
              style: text.labelLarge?.merge(onColor),
            ),
            Text(
              corner.ghost
                  ? '${corner.name} · ${l10n.ghostBadge}'
                  : corner.name,
              style: text.titleLarge?.merge(onColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Expanded(
              child: FittedBox(
                child: Text(
                  '${corner.points}',
                  style: text.displayLarge?.merge(onColor),
                ),
              ),
            ),
            Wrap(
              spacing: AppSpacing.m,
              children: [
                Text(l10n.warningsCount(corner.warnings), style: onColor),
                if (corner.oneHandRule)
                  Text(
                    l10n.oneHandCount(corner.oneHandWarnings),
                    style: onColor,
                  ),
                if (corner.disqualified)
                  Text(
                    l10n.disqualified,
                    style: text.titleMedium?.merge(onColor),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: color.onColor,
                      foregroundColor: color.color,
                      minimumSize: const Size(0, AppSizes.scoreTouchTarget),
                      textStyle: text.headlineMedium,
                    ),
                    onPressed: enabled ? onPoint : null,
                    child: Text(l10n.addPoint),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                PopupMenuButton<MatchAction>(
                  enabled: enabled,
                  iconColor: color.onColor,
                  iconSize: AppSizes.touchTarget,
                  onSelected: onSanction,
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: MatchAction.warning,
                      child: Text(l10n.actionWarning),
                    ),
                    if (corner.oneHandRule)
                      PopupMenuItem(
                        value: MatchAction.oneHandWarning,
                        child: Text(l10n.actionOneHand),
                      ),
                    PopupMenuItem(
                      value: MatchAction.disqualification,
                      child: Text(l10n.actionDisqualify),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
