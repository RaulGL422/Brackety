import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../mat/ui/fighter_text.dart';
import '../data/match_view.dart';

CompetitorColor cornerColor(Side side) =>
    side == Side.red ? CompetitorColor.red : CompetitorColor.blue;

String cornerName(AppLocalizations l10n, Side side) =>
    side == Side.red ? l10n.cornerRed : l10n.cornerBlue;

/// One fighter: big score, +1 and the warnings menu. Red and blue are fixed for this event.
/// Every line but the score keeps to one line, so it fits with the text at 200 %.
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
    final text = Theme.of(context).textTheme;
    final color = cornerColor(side);
    final onColor = TextStyle(color: color.onColor);
    return Material(
      color: color.color,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(side: side, corner: corner, style: onColor),
            if (corner.membersLine != null)
              Text(
                corner.membersLine!,
                style: text.bodySmall?.merge(onColor),
                maxLines: 1,
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
            _Tally(corner: corner, style: onColor.copyWith(fontSize: 14)),
            const SizedBox(height: AppSpacing.s),
            _Buttons(
              side: side,
              corner: corner,
              color: color,
              enabled: enabled,
              onPoint: onPoint,
              onSanction: onSanction,
            ),
          ],
        ),
      ),
    );
  }
}

/// "Rojo" over the name; the full name in the tooltip and to screen readers.
class _Header extends StatelessWidget {
  const _Header({
    required this.side,
    required this.corner,
    required this.style,
  });

  final Side side;
  final Corner corner;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final name = corner.label(l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Fixed at 14: the corner's height is shared with the score and the buttons.
        Text(
          cornerName(l10n, side),
          style: text.labelLarge?.merge(style).copyWith(fontSize: 14),
        ),
        Tooltip(
          message: name,
          // The text already gives the name to screen readers; the tooltip would repeat it.
          excludeFromSemantics: true,
          child: Text(
            name,
            style: text.titleLarge?.merge(style),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Warnings on one line, shrunk rather than cut when it does not fit.
class _Tally extends StatelessWidget {
  const _Tally({required this.corner, required this.style});

  final Corner corner;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.m,
        children: [
          Text(l10n.warningsCount(corner.warnings), style: style),
          if (corner.oneHandRule)
            Text(l10n.oneHandCount(corner.oneHandWarnings), style: style),
          if (corner.disqualified)
            Text(
              l10n.disqualified,
              style: Theme.of(context).textTheme.titleMedium?.merge(style),
            ),
        ],
      ),
    );
  }
}

class _Buttons extends StatelessWidget {
  const _Buttons({
    required this.side,
    required this.corner,
    required this.color,
    required this.enabled,
    required this.onPoint,
    required this.onSanction,
  });

  final Side side;
  final Corner corner;
  final CompetitorColor color;
  final bool enabled;
  final VoidCallback onPoint;
  final void Function(MatchAction action) onSanction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final cornerLabel = cornerName(l10n, side);
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: color.onColor,
              foregroundColor: color.color,
              minimumSize: const Size(0, AppSizes.scoreTouchTarget),
              textStyle: Theme.of(context).textTheme.headlineMedium,
            ),
            onPressed: enabled ? onPoint : null,
            child: Text(
              l10n.addPoint,
              maxLines: 1,
              semanticsLabel: l10n.addPointFor(cornerLabel),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        PopupMenuButton<MatchAction>(
          enabled: enabled,
          tooltip: l10n.sanctionsFor(cornerLabel),
          onSelected: onSanction,
          // Faded like the +1 button while nothing can be scored.
          child: Opacity(
            opacity: enabled ? 1 : 0.38,
            child: Container(
              width: AppSizes.scoreTouchTarget,
              height: AppSizes.scoreTouchTarget,
              decoration: BoxDecoration(
                border: Border.all(color: color.onColor, width: 2),
                borderRadius: BorderRadius.circular(AppRadius.m),
              ),
              child: Icon(
                Icons.flag_outlined,
                color: color.onColor,
                size: AppSizes.scoreIcon,
              ),
            ),
          ),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: MatchAction.warning,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.flag_outlined),
                title: Text(l10n.actionWarning),
              ),
            ),
            if (corner.oneHandRule)
              PopupMenuItem(
                value: MatchAction.oneHandWarning,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.back_hand_outlined),
                  title: Text(l10n.actionOneHand),
                ),
              ),
            const PopupMenuDivider(),
            // Apart and in the error colour: it ends the match.
            PopupMenuItem(
              value: MatchAction.disqualification,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                iconColor: scheme.error,
                textColor: scheme.error,
                leading: const Icon(Icons.block),
                title: Text(
                  l10n.actionDisqualify,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
