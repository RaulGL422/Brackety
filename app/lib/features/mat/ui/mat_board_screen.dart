import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/async_view.dart';
import '../../../core/group_colors.dart';
import '../../../core/keep_screen_on.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../offline/state/offline_sync.dart';
import '../../offline/ui/sync_status_bar.dart';
import '../../scoreboard/data/match_view.dart';
import '../data/mat_board.dart';
import '../state/mat_providers.dart';
import 'fighter_text.dart';

/// The referee's mat: its groups, the recommended match and every match by status.
/// With [readOnly] (the club) every match opens its timeline instead of the scoreboard.
/// The Android referee gets it through the device's queue and cache ([localBoardProvider]).
/// [matNumber] titles the screen before the board loads (or if it fails).
class MatBoardScreen extends ConsumerWidget {
  const MatBoardScreen({
    super.key,
    required this.matId,
    this.readOnly = false,
    this.matNumber,
  });

  final String matId;
  final bool readOnly;
  final int? matNumber;

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
    final number = board.value?.matNumber ?? matNumber;
    return KeepScreenOn(
      child: Scaffold(
        appBar: AppBar(
          title: Text(number == null ? '' : l10n.matTitle(number)),
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
              highlight: _Highlight.inProgress,
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
              highlight: _Highlight.recommended,
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

enum _Highlight { none, inProgress, recommended }

/// One match: group, red and blue, and why it waits. In progress: outlined, with a play icon.
/// Recommended: in the accent container, never a blue that looks like the blue corner. One
/// that cannot start keeps readable colours with a lock and its reason, and does not open.
class _MatchTile extends StatelessWidget {
  const _MatchTile({
    required this.board,
    required this.match,
    required this.readOnly,
    this.highlight = _Highlight.none,
  });

  final MatBoard board;
  final BoardMatch match;
  final bool readOnly;
  final _Highlight highlight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final finished = match.status == MatchStatus.finished;
    final waiting = match.status == MatchStatus.pending && !match.available;
    final locked = waiting && !readOnly;
    final recommended = highlight == _Highlight.recommended;
    final foreground = recommended
        ? scheme.onTertiaryContainer
        : scheme.onSurface;
    return Card(
      color: recommended ? scheme.tertiaryContainer : null,
      shape: highlight == _Highlight.inProgress
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.l),
              side: BorderSide(color: scheme.primary, width: AppSpacing.xs),
            )
          : null,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.xs,
      ),
      child: ListTile(
        minTileHeight: AppSizes.scoreTouchTarget,
        textColor: foreground,
        iconColor: foreground,
        leading: _GroupBadge(
          number: match.groupNumber,
          color: groupColor(board.groupIndex(match.groupId)),
          outline: foreground,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CornerLine(side: Side.red, fighter: match.red),
            _CornerLine(side: Side.blue, fighter: match.blue),
          ],
        ),
        subtitle: match.inReview
            ? Text(l10n.matInReview)
            : waiting
            ? Text(l10n.matWaiting)
            : null,
        trailing: finished
            ? Text(
                '${match.redScore} - ${match.blueScore}',
                style: theme.textTheme.titleLarge,
              )
            : Icon(
                locked
                    ? Icons.lock_outline
                    : switch (highlight) {
                        _Highlight.inProgress => Icons.play_circle,
                        _Highlight.recommended => Icons.star,
                        _Highlight.none => Icons.chevron_right,
                      },
              ),
        onTap: locked
            ? null
            : () => context.push(
                readOnly ? '/club/matches/${match.id}' : '/matches/${match.id}',
              ),
      ),
    );
  }
}

/// A coloured dot (with its corner's name for screen readers) and the fighter.
class _CornerLine extends StatelessWidget {
  const _CornerLine({required this.side, required this.fighter});

  final Side side;
  final Fighter fighter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final corner = side == Side.red ? l10n.cornerRed : l10n.cornerBlue;
    final color = side == Side.red ? CompetitorColor.red : CompetitorColor.blue;
    return Semantics(
      label: '$corner: ${fighter.label(l10n)}',
      excludeSemantics: true,
      child: Row(
        spacing: AppSpacing.s,
        children: [
          Container(
            width: AppSpacing.m,
            height: AppSpacing.m,
            decoration: BoxDecoration(
              color: color.color,
              shape: BoxShape.circle,
              border: Border.all(color: color.onColor),
            ),
          ),
          Expanded(child: Text(fighter.label(l10n))),
        ],
      ),
    );
  }
}

/// The group's colour and number; [outline] keeps it apart from a tile of a similar colour
/// (an orange group on the recommended tile).
class _GroupBadge extends StatelessWidget {
  const _GroupBadge({required this.number, required this.color, this.outline});

  final int number;
  final CompetitorColor color;
  final Color? outline;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: outline == null ? null : Border.all(color: outline!),
    ),
    child: CircleAvatar(
      backgroundColor: color.color,
      foregroundColor: color.onColor,
      child: Text('$number'),
    ),
  );
}
