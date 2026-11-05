import 'dart:async';

import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../mat/data/mat_board.dart';
import '../data/match_view.dart';
import '../state/match_controller.dart';

/// Big countdown with start/stop; once the match is over, the finish button instead.
class ClockBar extends ConsumerStatefulWidget {
  const ClockBar({super.key, required this.view, required this.onAction});

  final MatchView view;
  final void Function(MatchAction action) onAction;

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
    final l10n = AppLocalizations.of(context);
    final view = widget.view;
    final controller = ref.read(matchControllerProvider(view.id).notifier);
    final left = controller.remainingNow();
    final timeUp = view.running && left == Duration.zero;
    final over = view.endReason != null || timeUp;
    // In review nothing more is accepted until the club decides.
    final locked = view.review != null;
    final button = FilledButton.styleFrom(
      minimumSize: const Size(0, AppSizes.scoreTouchTarget),
      textStyle: Theme.of(context).textTheme.titleLarge,
    );
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!over)
            Text(_format(left), style: Theme.of(context).textTheme.displayLarge)
          else
            Text(switch (view.endReason) {
              EndReason.points => l10n.endPoints,
              EndReason.disqualification => l10n.endDisqualification,
              _ => l10n.endTime,
            }, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.s),
          SizedBox(
            width: double.infinity,
            child: over
                ? FilledButton.icon(
                    style: button,
                    icon: const Icon(Icons.flag),
                    label: Text(l10n.finishMatch),
                    onPressed: locked
                        ? null
                        : () => widget.onAction(MatchAction.finish),
                  )
                : view.running
                ? FilledButton.tonalIcon(
                    style: button,
                    icon: const Icon(Icons.pause),
                    label: Text(l10n.clockStop),
                    onPressed: locked
                        ? null
                        : () => widget.onAction(MatchAction.stop),
                  )
                : FilledButton.icon(
                    style: button,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      view.status == MatchStatus.pending
                          ? l10n.clockStart
                          : l10n.clockResume,
                    ),
                    onPressed: locked
                        ? null
                        : () => widget.onAction(MatchAction.start),
                  ),
          ),
        ],
      ),
    );
  }

  // Seconds round up, so 0:00 only shows when the time is really over.
  static String _format(Duration left) {
    final seconds = (left.inMilliseconds / 1000).ceil();
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}
