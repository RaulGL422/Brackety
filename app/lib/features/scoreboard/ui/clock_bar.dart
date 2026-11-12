import 'dart:async';

import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../mat/data/mat_board.dart';
import '../data/match_view.dart';
import '../state/bell.dart';
import '../state/match_controller.dart';
import 'undo_text.dart';

/// The last seconds show in the warning colour, and the clapper knocks once when they start.
const clockWarningFrom = Duration(seconds: 10);

/// What the referee can add to or take from the stopped clock.
const clockAdjustSteps = [
  Duration(seconds: -10),
  Duration(seconds: -1),
  Duration(seconds: 1),
  Duration(seconds: 10),
];

/// Below this height the landscape column has no room for the last actions.
const _recentMinHeight = 560.0;

/// The scoreboard's controls: big countdown, start/stop (finish once the match is over) and
/// undo saying what it undoes. With [clockHeight] the clock takes that height (portrait);
/// without it, all the room left (landscape, between the corners).
class ClockBar extends ConsumerStatefulWidget {
  const ClockBar({
    super.key,
    required this.view,
    required this.onAction,
    required this.onAdjust,
    this.clockHeight,
    this.banner,
  });

  final MatchView view;
  final void Function(MatchAction action) onAction;
  final void Function(Duration delta) onAdjust;
  final double? clockHeight;

  /// Shown over the clock, in the clock's own room: when it comes and goes (offline, actions
  /// waiting) only the digits shrink, and no button moves under the referee's thumb.
  final Widget? banner;

  @override
  ConsumerState<ClockBar> createState() => _ClockBarState();
}

class _ClockBarState extends ConsumerState<ClockBar> {
  late final Timer _ticker;
  var _warned = false;

  @override
  void initState() {
    super.initState();
    // Only this bar repaints several times a second, not the whole scoreboard.
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final controller = ref.read(
        matchControllerProvider(widget.view.id).notifier,
      );
      final left = controller.remainingNow();
      if (widget.view.running && left == Duration.zero) {
        controller.timeUp();
      }
      _warnTenSeconds(left);
      setState(() {});
    });
  }

  // Once per run into the last 10 s; more time on the clock (undo, adjustment) arms it again.
  void _warnTenSeconds(Duration left) {
    if (left > clockWarningFrom) {
      _warned = false;
    } else if (widget.view.running &&
        left > Duration.zero &&
        widget.view.endReason == null &&
        !_warned) {
      _warned = true;
      ref.read(bellProvider).play(BellSound.tenSeconds);
    }
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final left = ref
        .read(matchControllerProvider(view.id).notifier)
        .remainingNow();
    final over =
        view.endReason != null || (view.running && left == Duration.zero);
    final clock = _Clock(view: view, left: left, over: over);
    final clockButton = _ClockButton(
      view: view,
      over: over,
      onAction: widget.onAction,
    );
    final undo = _UndoButton(view: view, onAction: widget.onAction);
    // Only on a stopped clock of a match that the points or a disqualification did not end.
    final adjustable =
        view.started &&
        view.review == null &&
        (!view.running || left == Duration.zero) &&
        (view.endReason == null || view.endReason == EndReason.time);
    final adjust = adjustable
        ? _ClockAdjust(view: view, left: left, onAdjust: widget.onAdjust)
        : null;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: LayoutBuilder(
        builder: (context, size) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.s,
          children: [
            if (widget.clockHeight case final height?) ...[
              SizedBox(
                height: height,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ?widget.banner,
                    Expanded(child: clock),
                  ],
                ),
              ),
              ?adjust,
              // Portrait: both buttons on one row, under the thumb, the same height.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.s,
                  children: [
                    Expanded(child: clockButton),
                    Expanded(child: undo),
                  ],
                ),
              ),
            ] else ...[
              ?widget.banner,
              Expanded(child: clock),
              ?adjust,
              clockButton,
              undo,
              if (size.maxHeight >= _recentMinHeight)
                _RecentActions(view: view),
            ],
          ],
        ),
      ),
    );
  }
}

/// -10 s, -1 s, +1 s, +10 s on the stopped clock. A step that would leave the clock at 0 or
/// beyond the match length is off.
class _ClockAdjust extends StatelessWidget {
  const _ClockAdjust({
    required this.view,
    required this.left,
    required this.onAdjust,
  });

  final MatchView view;
  final Duration left;
  final void Function(Duration delta) onAdjust;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    bool allowed(Duration delta) =>
        delta.isNegative ? left + delta > Duration.zero : left < view.length;
    return Semantics(
      container: true,
      label: l10n.clockAdjustHint,
      child: Row(
        spacing: AppSpacing.xs,
        children: [
          for (final delta in clockAdjustSteps)
            Expanded(
              child: Tooltip(
                message: l10n.clockAdjustTooltip(signedSeconds(delta)),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, AppSizes.touchTarget),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: allowed(delta) ? () => onAdjust(delta) : null,
                  child: FittedBox(
                    child: Text(l10n.clockAdjustBy(signedSeconds(delta))),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The last referee actions, newest first; the one Undo takes back is marked.
class _RecentActions extends StatelessWidget {
  const _RecentActions({required this.view});

  final MatchView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final target = view.lastUndoable;
    final recent = view.timeline.reversed
        .where((e) => !e.automatic && e.action != MatchAction.undo)
        .take(3)
        .toList();
    if (recent.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.recentActions, style: text.labelMedium),
        for (final e in recent)
          Row(
            spacing: AppSpacing.s,
            children: [
              Text(clockText(e.clock), style: text.bodySmall),
              Expanded(
                child: Text(
                  _label(l10n, e),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: e.id != null && e.id == target?.id
                      ? text.bodyMedium?.copyWith(fontWeight: FontWeight.bold)
                      : text.bodyMedium?.copyWith(
                          decoration: e.undone
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                ),
              ),
              if (e.id != null && e.id == target?.id)
                const Icon(Icons.undo, size: 18),
            ],
          ),
      ],
    );
  }

  static String _label(AppLocalizations l10n, TimelineEntry e) =>
      switch (e.action) {
        MatchAction.start => l10n.tlStart,
        MatchAction.stop => l10n.tlStop,
        MatchAction.finish => l10n.tlFinish,
        _ => undoTarget(l10n, e),
      };
}

class _Clock extends StatelessWidget {
  const _Clock({required this.view, required this.left, required this.over});

  final MatchView view;
  final Duration left;
  final bool over;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final ending = !over && left <= clockWarningFrom;
    return FittedBox(
      child: over
          ? Text(switch (view.endReason) {
              EndReason.points => l10n.endPoints,
              EndReason.disqualification => l10n.endDisqualification,
              _ => l10n.endTime,
            }, style: text.headlineMedium)
          : Text(
              clockLabel(left),
              style: text.displayLarge?.copyWith(
                color: ending ? BracketyColors.of(context).warning : null,
              ),
            ),
    );
  }
}

/// "2:41". Seconds round up, so 0:00 only shows when the time is really over.
String clockLabel(Duration left) {
  final seconds = (left.inMilliseconds / 1000).ceil();
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

/// Start, stop or finish, by icon and word and without state colours: the colours on the
/// scoreboard are the competitors'. Stop is outlined, start and finish filled, so the button
/// also says whether the clock runs, and none looks like undo. In review
/// nothing is accepted.
class _ClockButton extends StatelessWidget {
  const _ClockButton({
    required this.view,
    required this.over,
    required this.onAction,
  });

  final MatchView view;
  final bool over;
  final void Function(MatchAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final locked = view.review != null;
    final (action, icon, label, background, foreground) = over
        ? (
            MatchAction.finish,
            Icons.flag,
            l10n.finishMatch,
            scheme.primary,
            scheme.onPrimary,
          )
        : view.running
        ? (
            MatchAction.stop,
            Icons.pause,
            l10n.clockStop,
            Colors.transparent,
            scheme.onSurface,
          )
        : (
            MatchAction.start,
            Icons.play_arrow,
            view.status == MatchStatus.pending
                ? l10n.clockStart
                : l10n.clockResume,
            scheme.primary,
            scheme.onPrimary,
          );
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        side: view.running && !over
            ? BorderSide(color: scheme.onSurface, width: 2)
            : null,
        iconSize: AppSizes.scoreIcon,
        minimumSize: const Size(0, AppSizes.scoreTouchTarget),
        textStyle: Theme.of(context).textTheme.titleLarge,
      ),
      icon: Icon(icon),
      // One word per line, shrunk only if a word still does not fit: wrapping by width broke
      // "Finalizar" in the middle on a narrow phone, and one shrunk line was too small to read.
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label.replaceFirst(' ', '\n'), textAlign: TextAlign.center),
      ),
      onPressed: locked ? null : () => onAction(action),
    );
  }
}

class _UndoButton extends StatelessWidget {
  const _UndoButton({required this.view, required this.onAction});

  final MatchView view;
  final void Function(MatchAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final target = view.review == null ? view.lastUndoable : null;
    // "Deshacer" and, under it, exactly what it takes back and at which match time.
    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, AppSizes.scoreTouchTarget),
      ),
      icon: const Icon(Icons.undo),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.undo, style: text.titleMedium, maxLines: 1),
          if (target != null)
            Text(
              l10n.undoDetail(
                undoTarget(l10n, target),
                clockText(target.clock),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
        ],
      ),
      onPressed: target == null ? null : () => onAction(MatchAction.undo),
    );
  }
}
