import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/async_view.dart';
import '../../../core/group_colors.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../offline/state/offline_sync.dart';
import '../../offline/ui/sync_status_bar.dart';
import '../data/mat_board.dart';
import '../state/mat_providers.dart';
import 'fighter_text.dart';

/// The referee's mat: its groups, the recommended match and every match by status.
/// With [readOnly] (the club) every match opens its timeline instead of the scoreboard.
/// The Android referee gets it through the device's queue and cache ([localBoardProvider]).
class MatBoardScreen extends ConsumerWidget {
  const MatBoardScreen({super.key, required this.matId, this.readOnly = false});

  final String matId;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final queued = !readOnly && ref.watch(offlineEnabledProvider);
    final provider = queued
        ? cachedBoardProvider(matId)
        : matBoardProvider(matId);
    final board = queued
        ? ref.watch(localBoardProvider(matId))
        : ref.watch(provider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          board.value == null ? '' : l10n.matTitle(board.value!.matNumber),
        ),
      ),
      body: Column(
        children: [
          if (queued) const SyncStatusBar(),
          Expanded(
            child: AsyncView(
              value: board,
              onRetry: () => ref.invalidate(provider),
              data: (board) => board.groups.isEmpty
                  ? Center(child: Text(l10n.matEmpty))
                  : RefreshIndicator(
                      onRefresh: () => ref.refresh(provider.future),
                      child: _BoardList(board: board, readOnly: readOnly),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardList extends StatelessWidget {
  const _BoardList({required this.board, required this.readOnly});

  final MatBoard board;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final byStatus = {
      for (final status in MatchStatus.values)
        status: board.matches.where((m) => m.status == status).toList(),
    };
    final recommended = board.matches
        .where((m) => m.id == board.recommendedMatchId)
        .firstOrNull;
    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.l,
        AppSpacing.l,
        AppSpacing.s,
      ),
      child: Text(title, style: text.titleMedium),
    );
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              for (final (i, g) in board.groups.indexed)
                _GroupCard(index: i, group: g),
            ],
          ),
        ),
        if (byStatus[MatchStatus.inProgress]!.isNotEmpty) ...[
          section(l10n.matInProgress),
          for (final m in byStatus[MatchStatus.inProgress]!)
            _MatchTile(
              board: board,
              readOnly: readOnly,
              match: m,
              highlight: true,
            ),
        ],
        if (board.offline)
          const _OfflineNotice()
        else ...[
          section(l10n.matRecommended),
          if (recommended == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Text(l10n.matNoneAvailable),
            )
          else
            _MatchTile(
              board: board,
              readOnly: readOnly,
              match: recommended,
              highlight: true,
            ),
        ],
        if (byStatus[MatchStatus.pending]!.isNotEmpty) ...[
          section(l10n.matPending),
          for (final m in byStatus[MatchStatus.pending]!)
            if (m.id != board.recommendedMatchId)
              _MatchTile(board: board, readOnly: readOnly, match: m),
        ],
        if (byStatus[MatchStatus.finished]!.isNotEmpty) ...[
          section(l10n.matFinished),
          for (final m in byStatus[MatchStatus.finished]!)
            _MatchTile(board: board, readOnly: readOnly, match: m),
        ],
      ],
    );
  }
}

/// Without network: the board saved here, and no recommendation.
class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) {
    final colors = BracketyColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: Card(
        color: colors.warningContainer,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Text(
            AppLocalizations.of(context).matOfflineBoard,
            style: TextStyle(color: colors.onWarningContainer),
          ),
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.index, required this.group});

  final int index;
  final BoardGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = groupColor(index);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _GroupBadge(number: group.number, color: color),
                const SizedBox(width: AppSpacing.s),
                Flexible(
                  child: Text(
                    l10n.matGroupHeader(group.number, group.categoryName),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            for (final m in group.members) ...[
              Text(m.label(l10n)),
              if (m.membersLine != null)
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.m,
                    bottom: AppSpacing.xs,
                  ),
                  child: Text(
                    m.membersLine!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    required this.board,
    required this.match,
    required this.readOnly,
    this.highlight = false,
  });

  final MatBoard board;
  final BoardMatch match;
  final bool readOnly;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final finished = match.status == MatchStatus.finished;
    final waiting = match.status == MatchStatus.pending && !match.available;
    return Card(
      color: highlight ? scheme.primaryContainer : null,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.xs,
      ),
      child: ListTile(
        minTileHeight: AppSizes.scoreTouchTarget,
        leading: _GroupBadge(
          number: match.groupNumber,
          color: groupColor(board.groupIndex(match.groupId)),
        ),
        title: Text(
          '${match.red.label(l10n)}  ${l10n.versus}  ${match.blue.label(l10n)}',
        ),
        subtitle: match.inReview
            ? Text(l10n.matInReview)
            : waiting
            ? Text(l10n.matWaiting)
            : null,
        trailing: finished
            ? Text(
                '${match.redScore} - ${match.blueScore}',
                style: Theme.of(context).textTheme.titleLarge,
              )
            : const Icon(Icons.chevron_right),
        enabled: readOnly || !waiting,
        onTap: () => context.push(
          readOnly ? '/club/matches/${match.id}' : '/matches/${match.id}',
        ),
      ),
    );
  }
}

class _GroupBadge extends StatelessWidget {
  const _GroupBadge({required this.number, required this.color});

  final int number;
  final CompetitorColor color;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    backgroundColor: color.color,
    foregroundColor: color.onColor,
    child: Text('$number'),
  );
}
