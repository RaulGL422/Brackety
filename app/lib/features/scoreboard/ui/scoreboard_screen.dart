import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/async_view.dart';
import '../../../core/keep_screen_on.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../mat/state/mat_providers.dart';
import '../../mat/ui/fighter_text.dart';
import '../../offline/ui/sync_status_bar.dart';
import '../data/match_view.dart';
import '../data/tambo_match.dart';
import '../state/bell.dart';
import '../state/match_controller.dart';
import 'clock_bar.dart';
import 'corner_panel.dart';
import 'final_score.dart';
import 'match_corrections.dart';
import 'reason_dialog.dart';
import 'timeline_list.dart';
import 'undo_text.dart';
import '../../../core/up_button.dart';

/// How long the "undone" message stays.
const undoneNotice = Duration(seconds: 3);

/// The scoreboard is always dark, in light mode too: the corners' red and blue at full
/// strength on ink, readable from the side of the mat.
final _scoreboardTheme = darkTheme();

/// The referee's scoreboard for one tambo match: clock, both corners, undo and finish.
class ScoreboardScreen extends ConsumerWidget {
  const ScoreboardScreen({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = matchControllerProvider(matchId);
    final match = ref.watch(provider);
    final view = match.value;
    // Any tap opens the browser's audio, so the bells that come later by themselves sound.
    return Listener(
      onPointerUp: (_) => ref.read(bellProvider).unlock(),
      child: KeepScreenOn(
        child: Theme(
          data: _scoreboardTheme,
          child: Scaffold(
            appBar: AppBar(
              leading: UpButton(
                label: view == null
                    ? l10n.eventsTitle
                    : l10n.matTitle(view.matNumber),
                fallback: view == null
                    ? '/'
                    : '/mats/${view.matId}?number=${view.matNumber}',
              ),
              leadingWidth: UpButton.leadingWidth(context),
              title: Text(
                view == null
                    ? ''
                    : l10n.scoreboardTitle(view.matNumber, view.groupNumber),
              ),
              actions: [
                if (view != null && view.started && !view.finished)
                  IconButton(
                    tooltip: l10n.cancelMatch,
                    icon: const Icon(Icons.block),
                    onPressed: () => cancelMatch(context, ref, matchId),
                  ),
                if (view != null)
                  IconButton(
                    tooltip: l10n.timeline,
                    icon: const Icon(Icons.history),
                    onPressed: () => _showTimeline(context, view),
                  ),
              ],
            ),
            body: Column(
              children: [
                // The finished view and errors still show it on top; the live scoreboard keeps it
                // in the clock's room (see ClockBar.banner).
                if (view == null || view.finished) const SyncStatusBar(),
                Expanded(
                  child: AsyncView(
                    value: match,
                    onRetry: () => ref.invalidate(provider),
                    data: (view) => view.finished
                        ? _Finished(
                            view: view,
                            onReopen: () => reopenMatch(context, ref, matchId),
                          )
                        : _Live(
                            view: view,
                            onAction: (action, {side}) =>
                                _act(context, ref, view, action, side: side),
                            onAdjust: (delta) => _send(
                              context,
                              ref,
                              MatchAction.clockAdjust,
                              delta: delta,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    MatchView view,
    MatchAction action, {
    Side? side,
  }) async {
    final l10n = AppLocalizations.of(context);
    String? reason;
    if (side != null &&
        action != MatchAction.point &&
        action != MatchAction.pointRemoved) {
      final label = switch (action) {
        MatchAction.oneHandWarning => l10n.actionOneHand,
        MatchAction.disqualification => l10n.actionDisqualify,
        _ => l10n.actionWarning,
      };
      reason = await askReason(
        context,
        title: l10n.reasonTitle(label, view.corner(side).title(l10n)),
        confirmLabel: action == MatchAction.disqualification
            ? l10n.reasonApplyDisqualify
            : l10n.reasonApplyWarning,
        destructive: action == MatchAction.disqualification,
      );
      if (reason == null || !context.mounted) return;
    }
    await _send(
      context,
      ref,
      action,
      side: side,
      reason: reason,
      undoing: action == MatchAction.undo ? view.lastUndoable : null,
    );
    // The match is over: the mat board must show the next recommendation.
    if (action == MatchAction.finish) {
      ref.invalidate(matBoardProvider(view.matId));
      ref.invalidate(cachedBoardProvider(view.matId));
    }
  }

  Future<void> _send(
    BuildContext context,
    WidgetRef ref,
    MatchAction action, {
    Side? side,
    String? reason,
    Duration? delta,
    TimelineEntry? undoing,
  }) async {
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    final refused = await ref
        .read(matchControllerProvider(matchId).notifier)
        .send(action, side: side, reason: reason, delta: delta);
    if (refused != null) {
      toasts.show(_refusalText(l10n, refused), kind: ToastKind.error);
    } else if (undoing != null) {
      toasts.show(
        l10n.undoneWhat(undoTarget(l10n, undoing)),
        duration: undoneNotice,
      );
    }
  }

  static String _refusalText(AppLocalizations l10n, ActionRefusal refusal) =>
      switch (refusal.local) {
        null => l10n.actionRefused(refusal.detail ?? ''),
        MatchRefusal.finished => l10n.refusalFinished,
        MatchRefusal.over => l10n.refusalOver,
        MatchRefusal.notStarted => l10n.refusalNotStarted,
        MatchRefusal.running => l10n.refusalRunning,
        MatchRefusal.notRunning => l10n.refusalNotRunning,
        MatchRefusal.nothingToUndo => l10n.refusalNothingToUndo,
        MatchRefusal.notOver => l10n.refusalNotOver,
        MatchRefusal.notFinished => l10n.refusalNotFinished,
        MatchRefusal.notForAge => l10n.refusalNotForAge,
        MatchRefusal.inReview => l10n.refusalInReview,
        MatchRefusal.matBusy => l10n.refusalMatBusy,
        MatchRefusal.noPoints => l10n.refusalNoPoints,
        MatchRefusal.clockRunning => l10n.refusalClockRunning,
        MatchRefusal.clockLimit => l10n.refusalClockLimit,
      };

  void _showTimeline(BuildContext context, MatchView view) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        builder: (_, controller) => TimelineList(
          view: view,
          controller: controller,
          markNextUndo: true,
        ),
      ),
    );
  }
}

/// Portrait: the controls on top and the corners stacked. Landscape (wider than tall: phone
/// on its side, tablet, desktop): red | controls | blue.
class _Live extends StatelessWidget {
  const _Live({
    required this.view,
    required this.onAction,
    required this.onAdjust,
  });

  final MatchView view;
  final void Function(MatchAction action, {Side? side}) onAction;
  final void Function(Duration delta) onAdjust;

  /// Share of the height the clock takes in portrait.
  static const _clockShare = 0.16;

  @override
  Widget build(BuildContext context) {
    final locked = view.review != null;
    // Nothing scores before the clock was first started (decided with Raul, 2026-11-06).
    final scoring = view.endReason == null && !locked && view.started;
    Widget corner(Side side) => Expanded(
      child: CornerPanel(
        side: side,
        corner: view.corner(side),
        enabled: scoring,
        // A correction: also once the time or the points ended it, not after a disqualification.
        canRemove:
            !locked &&
            view.started &&
            view.endReason != EndReason.disqualification &&
            view.corner(side).points > 0,
        onPoint: () => onAction(MatchAction.point, side: side),
        onRemovePoint: () => onAction(MatchAction.pointRemoved, side: side),
        onSanction: (action) => onAction(action, side: side),
      ),
    );
    return Column(
      children: [
        if (locked) const _ReviewBanner(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, size) {
              if (size.maxWidth > size.maxHeight) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    corner(Side.red),
                    Expanded(
                      child: ClockBar(
                        view: view,
                        onAction: onAction,
                        onAdjust: onAdjust,
                        banner: const SyncStatusBar(),
                      ),
                    ),
                    corner(Side.blue),
                  ],
                );
              }
              return Column(
                children: [
                  ClockBar(
                    view: view,
                    onAction: onAction,
                    onAdjust: onAdjust,
                    clockHeight: size.maxHeight * _clockShare,
                    banner: const SyncStatusBar(),
                  ),
                  corner(Side.red),
                  corner(Side.blue),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// The club has to review this match: the referee waits.
class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner();

  @override
  Widget build(BuildContext context) {
    final colors = BracketyColors.of(context);
    return Material(
      color: colors.warningContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Row(
          children: [
            Icon(Icons.gavel, color: colors.onWarningContainer),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: Text(
                AppLocalizations.of(context).reviewBannerReferee,
                style: TextStyle(color: colors.onWarningContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The result, then the timeline: side by side in landscape.
class _Finished extends StatelessWidget {
  const _Finished({required this.view, required this.onReopen});

  final MatchView view;

  /// Always offered: the server says no while another match is on the mat.
  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summary = SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.m,
        children: [
          Text(
            l10n.matchFinished,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          FinalScore(view: view),
          // Side by side: on a short phone a second row went under the timeline, out of sight.
          Row(
            spacing: AppSpacing.s,
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(l10n.backToMat),
                  ),
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go('/mats/${view.matId}'),
                ),
              ),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.lock_open),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(l10n.reopenMatch),
                  ),
                  onPressed: onReopen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, size) => size.maxWidth > size.maxHeight
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: summary),
                const VerticalDivider(width: 1),
                Expanded(child: TimelineList(view: view)),
              ],
            )
          : Column(
              children: [
                Flexible(child: summary),
                const Divider(height: 1),
                Expanded(child: TimelineList(view: view)),
              ],
            ),
    );
  }
}
