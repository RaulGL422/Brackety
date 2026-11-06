import 'dart:async';

import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../mat/data/mat_board.dart';
import '../data/match_view.dart';
import '../state/match_controller.dart';
import 'undo_text.dart';

/// The last seconds show in the warning colour.
const clockWarningFrom = Duration(seconds: 10);

/// The scoreboard's controls: big countdown, start/stop (finish once the match is over) and
/// undo saying what it undoes. With [clockHeight] the clock takes that height (portrait);
/// without it, all the room left (landscape, between the corners).
class ClockBar extends ConsumerStatefulWidget {
  const ClockBar({
    super.key,
    required this.view,
    required this.onAction,
    this.clockHeight,
  });

  final MatchView view;
  final void Function(MatchAction action) onAction;
  final double? clockHeight;

  @override
  ConsumerState<ClockBar> createState() => _ClockBarState();
}

class _ClockBarState extends ConsumerState<ClockBar> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    // Only this bar repaints several times a second, not the whole scoreboard.
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final controller = ref.read(
        matchControllerProvider(widget.view.id).notifier,
      );
      if (widget.view.running && controller.remainingNow() == Duration.zero) {
        controller.timeUp();
      }
      setState(() {});
    });
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
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.clockHeight case final height?)
            SizedBox(height: height, child: clock)
          else
            Expanded(child: clock),
          const SizedBox(height: AppSpacing.s),
          _ClockButton(view: view, over: over, onAction: widget.onAction),
          const SizedBox(height: AppSpacing.s),
          _UndoButton(view: view, onAction: widget.onAction),
        ],
      ),
    );
  }
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
              _format(left),
              style: text.displayLarge?.copyWith(
                color: ending ? BracketyColors.of(context).warning : null,
              ),
            ),
    );
  }

  // Seconds round up, so 0:00 only shows when the time is really over.
  static String _format(Duration left) {
    final seconds = (left.inMilliseconds / 1000).ceil();
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}

/// Start (green), stop (dark, strong) or finish; in review nothing is accepted.
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
    final colors = BracketyColors.of(context);
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
            scheme.inverseSurface,
            scheme.onInverseSurface,
          )
        : (
            MatchAction.start,
            Icons.play_arrow,
            view.status == MatchStatus.pending
                ? l10n.clockStart
                : l10n.clockResume,
            colors.success,
            colors.onSuccess,
          );
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        iconSize: AppSizes.scoreIcon,
        minimumSize: const Size(0, AppSizes.scoreTouchTarget),
        textStyle: Theme.of(context).textTheme.titleLarge,
      ),
      icon: Icon(icon),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
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
    final target = view.review == null ? view.lastUndoable : null;
    return OutlinedButton.icon(
      icon: const Icon(Icons.undo),
      label: Text(
        target == null ? l10n.undo : l10n.undoWhat(undoTarget(l10n, target)),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
      onPressed: target == null ? null : () => onAction(MatchAction.undo),
    );
  }
}
