import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../mat/ui/fighter_text.dart';
import '../data/match_view.dart';

CompetitorColor cornerColor(Side side) =>
    side == Side.red ? CompetitorColor.red : CompetitorColor.blue;

String cornerName(AppLocalizations l10n, Side side) =>
    side == Side.red ? l10n.cornerRed : l10n.cornerBlue;

/// One fighter: big score and the [buttons] below. Red and blue are fixed for this event.
/// Every line but the score keeps to one line, so it fits with the text at 200 %.
class CornerPanel extends StatelessWidget {
  const CornerPanel({
    super.key,
    required this.side,
    required this.corner,
    required this.buttons,
  });

  final Side side;
  final Corner corner;

  /// The corner's [CornerButtons].
  final Widget buttons;

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
            Expanded(
              child: LayoutBuilder(
                builder: (context, area) {
                  final details = [
                    _Header(side: side, corner: corner, style: onColor),
                    if (corner.membersLine != null)
                      Text(
                        corner.membersLine!,
                        style: text.bodySmall?.merge(onColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ];
                  final tally = _Tally(
                    corner: corner,
                    style: onColor.copyWith(fontSize: 14),
                  );
                  final score = FittedBox(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${corner.points}',
                      style: text.displayLarge
                          ?.merge(onColor)
                          .copyWith(height: 1),
                    ),
                  );
                  // A phone held upright leaves the corner wide and low: the score beside the name
                  // takes the whole height, instead of the thin strip between the name and the warnings.
                  if (area.maxWidth > area.maxHeight * 1.2) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpacing.s,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [...details, const Spacer(), tally],
                          ),
                        ),
                        Expanded(flex: 2, child: score),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...details,
                      Expanded(
                        child: FittedBox(
                          child: Text(
                            '${corner.points}',
                            style: text.displayLarge?.merge(onColor),
                          ),
                        ),
                      ),
                      tally,
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            buttons,
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
