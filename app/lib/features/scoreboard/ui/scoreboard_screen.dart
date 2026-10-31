import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/async_view.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../mat/state/mat_providers.dart';
import '../data/match_view.dart';
import '../state/match_controller.dart';
import 'clock_bar.dart';
import 'corner_panel.dart';
import 'reason_dialog.dart';
import 'timeline_list.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          view == null
              ? ''
              : l10n.scoreboardTitle(view.matNumber, view.groupNumber),
        ),
        actions: [
          if (view != null) ...[
            TextButton.icon(
              icon: const Icon(Icons.undo),
              label: Text(l10n.undo),
              onPressed: view.canUndo
                  ? () => _send(context, ref, MatchAction.undo)
                  : null,
            ),
            IconButton(
              tooltip: l10n.timeline,
              icon: const Icon(Icons.history),
              onPressed: () => _showTimeline(context, view),
            ),
          ],
        ],
      ),
      body: AsyncView(
        value: match,
        onRetry: () => ref.invalidate(provider),
        data: (view) => view.finished
            ? _Finished(view: view)
            : _Live(
                view: view,
                onAction: (action, {side}) =>
                    _act(context, ref, view, action, side: side),
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
    if (side != null && action != MatchAction.point) {
      final label = switch (action) {
        MatchAction.oneHandWarning => l10n.actionOneHand,
        MatchAction.disqualification => l10n.actionDisqualify,
        _ => l10n.actionWarning,
      };
      reason = await askReason(
        context,
        title: l10n.reasonTitle(label, view.corner(side).name),
      );
      if (reason == null || !context.mounted) return;
    }
    await _send(context, ref, action, side: side, reason: reason);
    // The match is over: the mat board must show the next recommendation.
    if (action == MatchAction.finish) {
      ref.invalidate(matBoardProvider(view.matId));
    }
  }

  Future<void> _send(
    BuildContext context,
    WidgetRef ref,
    MatchAction action, {
    Side? side,
    String? reason,
  }) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final refused = await ref
        .read(matchControllerProvider(matchId).notifier)
        .send(action, side: side, reason: reason);
    if (refused != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.actionRefused(refused))),
      );
    }
  }

  void _showTimeline(BuildContext context, MatchView view) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        builder: (_, controller) =>
            TimelineList(view: view, controller: controller),
      ),
    );
  }
}

class _Live extends StatelessWidget {
  const _Live({required this.view, required this.onAction});

  final MatchView view;
  final void Function(MatchAction action, {Side? side}) onAction;

  @override
  Widget build(BuildContext context) {
    final scoring = view.endReason == null;
    Widget corner(Side side) => Expanded(
      child: CornerPanel(
        side: side,
        corner: view.corner(side),
        enabled: scoring,
        onPoint: () => onAction(MatchAction.point, side: side),
        onSanction: (action) => onAction(action, side: side),
      ),
    );
    // Side by side when there is room (tablet, landscape phone); stacked on a portrait phone.
    final wide = MediaQuery.sizeOf(context).aspectRatio > 0.8;
    final corners = [corner(Side.red), corner(Side.blue)];
    return Column(
      children: [
        ClockBar(view: view, onAction: (action) => onAction(action)),
        Expanded(
          child: wide ? Row(children: corners) : Column(children: corners),
        ),
      ],
    );
  }
}

class _Finished extends StatelessWidget {
  const _Finished({required this.view});

  final MatchView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            children: [
              Text(l10n.matchFinished, style: text.headlineSmall),
              const SizedBox(height: AppSpacing.s),
              Text(
                '${view.red.name}  ${view.red.points} - ${view.blue.points}  ${view.blue.name}',
                style: text.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.m),
              FilledButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.backToMat),
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go('/mats/${view.matId}'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: TimelineList(view: view)),
      ],
    );
  }
}
