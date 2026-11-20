import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/match_view.dart';
import '../data/scoring.dart';
import 'corner_panel.dart';

/// What the corner's menu does: a warning, a disqualification, a [finish] (a sport's action
/// that wins at once, by name) or taking back [points].
typedef CornerChoice = ({MatchAction action, String? finish, int points});

/// The corner's buttons, as the sport's rules say. [canPoint]: the points, also when the clock
/// already shows 0:00 (F1-3). [canSanction]: the menu. [canRemove]: taking points back is a
/// correction, also once the time or the points ended the match. [extraTimeDue]: a tie no
/// tiebreak settled; the referee says who won. The buttons: tambo's +1 and −1, or a button for each
/// value (grappling: +1 to +4); and the menu with the warnings, the actions that win at once,
/// the disqualification and, with several values, taking one back. While the extra time is
/// due, only who won it.
class CornerButtons extends StatelessWidget {
  const CornerButtons({
    super.key,
    required this.side,
    required this.corner,
    required this.scoring,
    required this.canPoint,
    required this.canSanction,
    required this.canRemove,
    required this.extraTimeDue,
    required this.onPoint,
    required this.onRemovePoint,
    required this.onChoice,
  });

  final Side side;
  final Corner corner;
  final Scoring scoring;
  final bool canPoint;
  final bool canSanction;
  final bool canRemove;
  final bool extraTimeDue;
  final void Function(int value) onPoint;
  final void Function(int value) onRemovePoint;
  final void Function(CornerChoice choice) onChoice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cornerLabel = cornerName(l10n, side);
    final color = cornerColor(side);
    final strong = FilledButton.styleFrom(
      backgroundColor: color.onColor,
      foregroundColor: color.color,
      minimumSize: const Size(0, AppSizes.scoreTouchTarget),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      textStyle: Theme.of(context).textTheme.headlineMedium,
    );
    if (extraTimeDue) {
      return FilledButton.icon(
        style: strong.copyWith(
          textStyle: WidgetStatePropertyAll(
            Theme.of(context).textTheme.titleLarge,
          ),
        ),
        icon: const Icon(Icons.emoji_events_outlined),
        label: Text(
          l10n.extraTimeWon,
          maxLines: 1,
          semanticsLabel: l10n.extraTimeWonBy(cornerLabel),
        ),
        onPressed: () =>
            onChoice((action: MatchAction.extraTime, finish: null, points: 1)),
      );
    }
    final values = {for (final a in scoring.actions) a.value}.toList()..sort();
    Widget point(int value) => Expanded(
      child: _PointButton(
        value: value,
        // Tambo: one +1 with its usual words; otherwise +N, with what it is for.
        labels: values.length == 1
            ? null
            : [
                for (final a in scoring.actions)
                  if (a.value == value) a.label,
              ].join(' · '),
        cornerLabel: cornerLabel,
        style: strong,
        onPressed: canPoint ? () => onPoint(value) : null,
      ),
    );

    final menu = _Menu(
      corner: corner,
      scoring: scoring,
      color: color,
      cornerLabel: cornerLabel,
      canSanction: canSanction,
      // Tambo has its own −1 button.
      removable: values.length == 1 || !canRemove ? const [] : values,
      onChoice: (choice) => choice.action == MatchAction.pointRemoved
          ? onRemovePoint(choice.points)
          : onChoice(choice),
    );
    if (values.length == 1) {
      return Row(
        spacing: AppSpacing.s,
        children: [
          point(values.single),
          // Outlined and narrower than +1, so it is not pressed instead of it.
          Tooltip(
            message: l10n.removePointFor(cornerLabel),
            child: _Outlined(
              color: color,
              enabled: canRemove,
              onPressed: () => onRemovePoint(values.single),
              child: Text(
                l10n.removePoint,
                semanticsLabel: l10n.removePointFor(cornerLabel),
              ),
            ),
          ),
          menu,
        ],
      );
    }
    // One row, so it fits a phone held upright; taking a value back is in the menu.
    return Row(
      spacing: AppSpacing.xs,
      children: [for (final v in values) point(v), menu],
    );
  }
}

/// +N for the corner; [labels]: what the button is for, said to screen readers and in its
/// tooltip; null for tambo's single +1.
class _PointButton extends StatelessWidget {
  const _PointButton({
    required this.value,
    required this.labels,
    required this.cornerLabel,
    required this.style,
    required this.onPressed,
  });

  final int value;
  final String? labels;
  final String cornerLabel;
  final ButtonStyle style;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = this.labels;
    final button = FilledButton(
      style: style,
      onPressed: onPressed,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          labels == null ? l10n.addPoint : '+$value',
          maxLines: 1,
          semanticsLabel: labels == null
              ? l10n.addPointFor(cornerLabel)
              : l10n.addPointsFor(value, cornerLabel, labels),
        ),
      ),
    );
    return labels == null ? button : Tooltip(message: labels, child: button);
  }
}

/// The −1 of tambo: outlined, square.
class _Outlined extends StatelessWidget {
  const _Outlined({
    required this.color,
    required this.enabled,
    required this.onPressed,
    required this.child,
  });

  final CompetitorColor color;
  final bool enabled;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      foregroundColor: color.onColor,
      disabledForegroundColor: color.onColor.withValues(alpha: 0.38),
      side: BorderSide(
        color: color.onColor.withValues(alpha: enabled ? 1 : 0.38),
        width: 2,
      ),
      minimumSize: const Size(
        AppSizes.scoreTouchTarget,
        AppSizes.scoreTouchTarget,
      ),
      padding: EdgeInsets.zero,
      textStyle: Theme.of(context).textTheme.headlineSmall,
    ),
    onPressed: enabled ? onPressed : null,
    child: child,
  );
}

/// The look of a menu that opens from the corner: a bordered box, faded while disabled.
class _OutlinedBox extends StatelessWidget {
  const _OutlinedBox({
    required this.color,
    required this.enabled,
    required this.child,
    this.width,
  });

  final CompetitorColor color;
  final bool enabled;
  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: enabled ? 1 : 0.38,
    child: Container(
      width: width,
      height: AppSizes.scoreTouchTarget,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: color.onColor, width: 2),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: child,
    ),
  );
}

/// Warnings, the actions that win at once, and the disqualification.
class _Menu extends StatelessWidget {
  const _Menu({
    required this.corner,
    required this.scoring,
    required this.color,
    required this.cornerLabel,
    required this.canSanction,
    required this.removable,
    required this.onChoice,
  });

  final Corner corner;
  final Scoring scoring;
  final CompetitorColor color;
  final String cornerLabel;
  final bool canSanction;

  /// The values that can be taken back; empty: none.
  final List<int> removable;
  final void Function(CornerChoice choice) onChoice;

  @override
  Widget build(BuildContext context) {
    final enabled = canSanction || removable.isNotEmpty;
    return PopupMenuButton<CornerChoice>(
      enabled: enabled,
      tooltip: AppLocalizations.of(context).sanctionsFor(cornerLabel),
      onSelected: onChoice,
      itemBuilder: _items,
      // Faded like the point buttons while nothing can be scored.
      child: _OutlinedBox(
        color: color,
        enabled: enabled,
        width: AppSizes.scoreTouchTarget,
        child: Icon(
          Icons.flag_outlined,
          color: color.onColor,
          size: AppSizes.scoreIcon,
        ),
      ),
    );
  }

  PopupMenuItem<CornerChoice> _item(
    MatchAction action,
    IconData icon,
    String title, {
    String? finish,
    int points = 1,
    bool? enabled,
    Color? color,
  }) => PopupMenuItem(
    value: (action: action, finish: finish, points: points),
    enabled: enabled ?? canSanction,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      iconColor: color,
      textColor: color,
      leading: Icon(icon),
      // Only the disqualification has a colour of its own, and it is bold too.
      title: Text(
        title,
        style: color == null
            ? null
            : const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  );

  List<PopupMenuEntry<CornerChoice>> _items(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = Theme.of(context).colorScheme.error;
    return [
      _item(MatchAction.warning, Icons.flag_outlined, l10n.actionWarning),
      if (corner.oneHandRule)
        _item(
          MatchAction.oneHandWarning,
          Icons.back_hand_outlined,
          l10n.actionOneHand,
        ),
      if (scoring.finishes.isNotEmpty) const PopupMenuDivider(),
      for (final finish in scoring.finishes)
        _item(
          MatchAction.submission,
          Icons.emoji_events_outlined,
          finish,
          finish: finish,
        ),
      const PopupMenuDivider(),
      // Apart and in the error colour: it ends the match.
      _item(
        MatchAction.disqualification,
        Icons.block,
        l10n.actionDisqualify,
        color: error,
      ),
      if (removable.isNotEmpty) const PopupMenuDivider(),
      for (final v in removable)
        _item(
          MatchAction.pointRemoved,
          Icons.remove_circle_outline,
          l10n.removePointsValue(v),
          points: v,
          enabled: corner.points >= v,
        ),
    ];
  }
}
