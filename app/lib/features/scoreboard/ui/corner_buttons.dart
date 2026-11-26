import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../match/data/match_view.dart';
import '../../match/data/scoring.dart';
import '../../match/ui/corner.dart';

/// What a corner's warnings menu or win button does: a warning, a disqualification or a [finish]
/// (a sport's action that wins at once, by name).
typedef CornerChoice = ({MatchAction action, String? finish});

/// The corner's buttons, as the sport's rules say (GR-1, decided with Raul 2026-11-23): each value
/// as a pair [+N|−N], two pairs a row; each action that wins at once (grappling: submission) as a
/// button of its own; the flag only for the warnings and the disqualification. [canPoint]: the
/// points, also when the clock already shows 0:00 (F1-3). [canSanction]: the flag and the wins.
/// [canRemove]: taking points back is a correction, also once the time or the points ended the
/// match. [extraTimeDue]: a tie no tiebreak settled; the referee says who won, and only that.
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
    this.short = false,
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

  /// Little height for the corner (a phone): the wins go as square buttons beside the pairs.
  final bool short;
  final void Function(int value) onPoint;
  final void Function(int value) onRemovePoint;
  final void Function(CornerChoice choice) onChoice;

  /// Several rows in a short corner must leave the score room; still well over 48.
  static const _rowsHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cornerLabel = cornerName(l10n, side);
    final color = cornerColor(side);
    final textTheme = Theme.of(context).textTheme;
    final values = {for (final a in scoring.actions) a.value}.toList()..sort();
    final rows =
        (values.length + 1) ~/ 2 + (scoring.finishes.isEmpty || short ? 0 : 1);
    final height = short && rows > 1 ? _rowsHeight : AppSizes.scoreTouchTarget;
    final strong = FilledButton.styleFrom(
      backgroundColor: color.onColor,
      foregroundColor: color.color,
      minimumSize: Size(0, height),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      textStyle: textTheme.headlineMedium,
    );
    if (extraTimeDue) {
      return _WinButton(
        style: strong,
        text: l10n.extraTimeWon,
        semantics: l10n.extraTimeWonBy(cornerLabel),
        onPressed: () =>
            onChoice((action: MatchAction.extraTime, finish: null)),
      );
    }
    final pairs = [
      for (final value in values)
        Expanded(
          child: _PointPair(
            value: value,
            // Tambo's single +1 needs no words; otherwise what each value is for.
            labels: values.length == 1
                ? null
                : [
                    for (final a in scoring.actions)
                      if (a.value == value) a.label,
                  ].join(' · '),
            cornerLabel: cornerLabel,
            color: color,
            height: height,
            style: strong,
            onAdd: canPoint ? () => onPoint(value) : null,
            onRemove: canRemove && corner.points >= value
                ? () => onRemovePoint(value)
                : null,
          ),
        ),
    ];
    final flag = _Menu(
      corner: corner,
      color: color,
      size: height,
      cornerLabel: cornerLabel,
      enabled: canSanction,
      onChoice: onChoice,
    );
    Widget win(String finish, {double? square}) => _WinButton(
      style: strong,
      text: finish,
      semantics: l10n.finishFor(finish, cornerLabel),
      square: square,
      onPressed: canSanction
          ? () => onChoice((action: MatchAction.submission, finish: finish))
          : null,
    );
    final lines = <List<Widget>>[
      for (var i = 0; i < pairs.length; i += 2)
        [pairs[i], if (i + 1 < pairs.length) pairs[i + 1]],
    ];
    if (scoring.finishes.isEmpty) {
      lines.last.add(flag);
    } else if (short) {
      // A short corner (phone): no row of its own; the wins close the last row, the flag the first.
      lines.first.add(flag);
      lines.last.addAll([
        for (final f in scoring.finishes) win(f, square: height),
      ]);
    } else {
      if (lines.length > 1 && lines.last.length == 1) {
        lines.last.add(const Spacer());
      }
      lines.add([
        for (final finish in scoring.finishes) Expanded(child: win(finish)),
        flag,
      ]);
    }
    return Column(
      spacing: AppSpacing.xs,
      children: [
        // Fixed: with large text the labels shrink, the rows do not grow over the score.
        for (final line in lines)
          SizedBox(
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.s,
              children: line,
            ),
          ),
      ],
    );
  }
}

/// [+N|−N] side by side: the − outlined and narrower, so it is not pressed instead of the +.
/// [labels]: what the value is for, said to screen readers and in the tooltip; null for tambo.
class _PointPair extends StatelessWidget {
  const _PointPair({
    required this.value,
    required this.labels,
    required this.cornerLabel,
    required this.color,
    required this.height,
    required this.style,
    required this.onAdd,
    required this.onRemove,
  });

  final int value;
  final String? labels;
  final String cornerLabel;
  final CompetitorColor color;
  final double height;
  final ButtonStyle style;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = this.labels;
    Widget add = FilledButton(
      style: style,
      onPressed: onAdd,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '+$value',
          maxLines: 1,
          semanticsLabel: labels == null
              ? l10n.addPointFor(cornerLabel)
              : l10n.addPointsFor(value, cornerLabel, labels),
        ),
      ),
    );
    if (labels != null) add = Tooltip(message: labels, child: add);
    final removeLabel = l10n.removePointsFor(value, cornerLabel);
    final enabled = onRemove != null;
    return Row(
      spacing: AppSpacing.xs,
      children: [
        Expanded(flex: 3, child: add),
        Expanded(
          flex: 2,
          child: Tooltip(
            message: removeLabel,
            excludeFromSemantics: true,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: color.onColor,
                disabledForegroundColor: color.onColor.withValues(alpha: 0.38),
                side: BorderSide(
                  color: color.onColor.withValues(alpha: enabled ? 1 : 0.38),
                  width: 2,
                ),
                minimumSize: Size(0, height),
                padding: EdgeInsets.zero,
                textStyle: Theme.of(context).textTheme.headlineSmall,
              ),
              onPressed: onRemove,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '−$value',
                  maxLines: 1,
                  semanticsLabel: removeLabel,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A button that wins the match at once: a sport's finish, or the extra time.
class _WinButton extends StatelessWidget {
  const _WinButton({
    required this.style,
    required this.text,
    required this.semantics,
    required this.onPressed,
    this.square,
  });

  final ButtonStyle style;
  final String text;
  final String semantics;
  final VoidCallback? onPressed;

  /// The side of an icon-only button, its name in the tooltip; null: icon and name.
  final double? square;

  @override
  Widget build(BuildContext context) {
    final square = this.square;
    if (square != null) {
      return Tooltip(
        message: text,
        excludeFromSemantics: true,
        child: Semantics(
          label: semantics,
          button: true,
          excludeSemantics: true,
          child: SizedBox.square(
            dimension: square,
            child: FilledButton(
              style: style.copyWith(
                padding: const WidgetStatePropertyAll(EdgeInsets.zero),
              ),
              onPressed: onPressed,
              child: const Icon(
                Icons.emoji_events_outlined,
                size: AppSizes.scoreIcon,
              ),
            ),
          ),
        ),
      );
    }
    return FilledButton.icon(
      style: style.copyWith(
        textStyle: WidgetStatePropertyAll(
          Theme.of(context).textTheme.titleLarge,
        ),
        iconSize: const WidgetStatePropertyAll(32),
      ),
      icon: const Icon(Icons.emoji_events_outlined),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(text, maxLines: 1, semanticsLabel: semantics),
      ),
      onPressed: onPressed,
    );
  }
}

/// The flag: warnings and the disqualification, nothing else.
class _Menu extends StatelessWidget {
  const _Menu({
    required this.corner,
    required this.color,
    required this.size,
    required this.cornerLabel,
    required this.enabled,
    required this.onChoice,
  });

  final Corner corner;
  final CompetitorColor color;
  final double size;
  final String cornerLabel;
  final bool enabled;
  final void Function(CornerChoice choice) onChoice;

  @override
  Widget build(BuildContext context) => PopupMenuButton<CornerChoice>(
    enabled: enabled,
    tooltip: AppLocalizations.of(context).sanctionsFor(cornerLabel),
    onSelected: onChoice,
    itemBuilder: _items,
    // Faded like the point buttons while nothing can be scored.
    child: Opacity(
      opacity: enabled ? 1 : 0.38,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
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
  );

  PopupMenuItem<CornerChoice> _item(
    MatchAction action,
    IconData icon,
    String title, {
    Color? color,
  }) => PopupMenuItem(
    value: (action: action, finish: null),
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
    return [
      _item(MatchAction.warning, Icons.flag_outlined, l10n.actionWarning),
      if (corner.oneHandRule)
        _item(
          MatchAction.oneHandWarning,
          Icons.back_hand_outlined,
          l10n.actionOneHand,
        ),
      const PopupMenuDivider(),
      // Apart and in the error colour: it ends the match.
      _item(
        MatchAction.disqualification,
        Icons.block,
        l10n.actionDisqualify,
        color: Theme.of(context).colorScheme.error,
      ),
    ];
  }
}
