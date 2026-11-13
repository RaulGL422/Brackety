import 'dart:async';

import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/async_view.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../mat/data/mat_board.dart';
import '../data/match_view.dart';
import '../../offline/state/offline_sync.dart';
import '../state/match_review.dart';
import 'clock_bar.dart';
import 'final_score.dart';
import 'review_panel.dart';
import 'timeline_list.dart';
import '../../../core/up_button.dart';
import '../../mat/ui/mat_label.dart';

/// A match seen by the club: score and timeline, without controls. In review, what the phone
/// sent and the buttons to apply or discard it.
class MatchWatchScreen extends ConsumerWidget {
  const MatchWatchScreen({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = watchedMatchProvider(matchId);
    final match = ref.watch(provider);
    return Scaffold(
      appBar: AppBar(
        leading: UpButton(
          label: match.value == null
              ? l10n.eventsTitle
              : matLabel(l10n, match.value!.matNumber),
          fallback: match.value?.matId == null
              ? '/'
              : '/club/mats/${match.value!.matId}?number=${match.value!.matNumber}',
        ),
        leadingWidth: UpButton.leadingWidth(context),
        title: Text(switch (match.value) {
          final view? => l10n.scoreboardTitle(
            matLabel(l10n, view.matNumber),
            view.groupNumber,
          ),
          null => l10n.timeline,
        }),
      ),
      persistentFooterButtons: match.value?.review == null
          ? null
          : [ReviewButtons(matchId: matchId)],
      body: AsyncView(
        value: match,
        onRetry: () => ref.invalidate(provider),
        data: (view) => Column(
          children: [
            // Shares the height with the timeline; scrolls when the phone sent many actions
            // or the text is large.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _Score(view: view),
                    if (view.review != null) ReviewPanel(view: view),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(child: TimelineList(view: view)),
          ],
        ),
      ),
    );
  }
}

/// The time left, counted on this device from what the server last said (as the referee's
/// clock does) and set right again with every update: running or stopped, or why it ended.
class _WatchClock extends ConsumerStatefulWidget {
  const _WatchClock({required this.view});

  final MatchView view;

  @override
  ConsumerState<_WatchClock> createState() => _WatchClockState();
}

class _WatchClockState extends ConsumerState<_WatchClock> {
  late final _now = ref.read(deviceClockProvider);
  late var _received = _now();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => setState(() {}),
    );
  }

  @override
  void didUpdateWidget(_WatchClock old) {
    super.didUpdateWidget(old);
    if (!identical(old.view, widget.view)) _received = _now();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final view = widget.view;
    final left = view.running
        ? view.remaining - _now().difference(_received)
        : view.remaining;
    final over = view.endReason != null || left <= Duration.zero;
    return Column(
      children: [
        Text(
          over
              ? switch (view.endReason) {
                  EndReason.points => l10n.endPoints,
                  EndReason.disqualification => l10n.endDisqualification,
                  _ => l10n.endTime,
                }
              : clockLabel(left),
          style: text.displayMedium,
        ),
        if (!over)
          Text(
            view.running ? l10n.watchClockRunning : l10n.watchClockStopped,
            style: text.bodyMedium,
          ),
      ],
    );
  }
}

class _Score extends StatelessWidget {
  const _Score({required this.view});

  final MatchView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        children: [
          Text(switch (view.status) {
            MatchStatus.pending => l10n.matchNotStarted,
            MatchStatus.inProgress => l10n.matchLive,
            MatchStatus.finished => l10n.matchFinished,
          }, style: Theme.of(context).textTheme.titleMedium),
          if (view.status == MatchStatus.inProgress) _WatchClock(view: view),
          const SizedBox(height: AppSpacing.s),
          FinalScore(view: view, showWinner: view.finished),
        ],
      ),
    );
  }
}
