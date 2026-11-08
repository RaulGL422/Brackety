import 'dart:math';

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

/// The referee's mat: what to do now first (the match in progress, the next one), then
/// what comes later, what is finished and the groups on it.
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
    final colors = BracketyColors.of(context);
    final text = Theme.of(context).textTheme;
    final queued = !readOnly && ref.watch(offlineEnabledProvider);
    final provider = queued
        ? cachedBoardProvider(matId)
        : matBoardProvider(matId);
    final board = queued
        ? ref.watch(localBoardProvider(matId))
        : ref.watch(provider);
    final number = board.value?.matNumber ?? matNumber;
    final toPlay = board.value?.matches
        .where((m) => m.status != MatchStatus.finished)
        .length;
    return KeepScreenOn(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colors.band,
          foregroundColor: colors.onBand,
          shape: const Border(),
          toolbarHeight: 88,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!readOnly)
                Text(
                  l10n.matYours,
                  style: text.bodyMedium?.copyWith(color: colors.onBand),
                ),
              Text(
                number == null ? '' : l10n.matTitle(number),
                style: text.displaySmall?.copyWith(color: colors.onBand),
              ),
            ],
          ),
          actions: [
            if (toPlay != null && toPlay > 0)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.l),
                child: Text(
                  l10n.matToPlay(toPlay),
                  style: text.bodyMedium?.copyWith(color: colors.onBand),
                ),
              ),
          ],
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
    final later = [
      for (final m in byStatus[MatchStatus.pending]!)
        if (m.id != board.recommendedMatchId) m,
    ];
    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.s),
      child: Text(title, style: text.titleMedium),
    );
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        padding: EdgeInsets.fromLTRB(
          _gutter(constraints.maxWidth),
          AppSpacing.l,
          _gutter(constraints.maxWidth),
          AppSpacing.xxl,
        ),
        children: [
          for (final m in byStatus[MatchStatus.inProgress]!)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.l),
              child: _FeaturedMatch(
                board: board,
                match: m,
                readOnly: readOnly,
                inProgress: true,
              ),
            ),
          if (board.offline)
            const _OfflineNotice()
          else if (recommended == null)
            Text(l10n.matNoneAvailable)
          else
            _FeaturedMatch(
              board: board,
              match: recommended,
              readOnly: readOnly,
            ),
          if (later.isNotEmpty) ...[
            section(l10n.matPending),
            _MatchList(board: board, matches: later, readOnly: readOnly),
          ],
          if (byStatus[MatchStatus.finished]!.isNotEmpty) ...[
            section(l10n.matFinished),
            _MatchList(
              board: board,
              matches: byStatus[MatchStatus.finished]!,
              readOnly: readOnly,
            ),
          ],
          section(l10n.matGroups),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              for (final (i, g) in board.groups.indexed)
                _GroupCard(index: i, group: g),
            ],
          ),
        ],
      ),
    );
  }

  /// On wide windows the board keeps a reading width instead of stretching.
  static double _gutter(double width) =>
      max(AppSpacing.l, (width - AppSizes.readingMaxWidth) / 2);
}

/// Without network: the board saved here, and no recommendation.
class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) {
    final colors = BracketyColors.of(context);
    return Card(
      color: colors.warningContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Text(
          AppLocalizations.of(context).matOfflineBoard,
          style: TextStyle(color: colors.onWarningContainer),
        ),
      ),
    );
  }
}

/// The match to act on: the one in progress (ink band) or the next one (gold band),
/// with both fighters large and one clear button.
class _FeaturedMatch extends StatelessWidget {
  const _FeaturedMatch({
    required this.board,
    required this.match,
    required this.readOnly,
    this.inProgress = false,
  });

  final MatBoard board;
  final BoardMatch match;
  final bool readOnly;
  final bool inProgress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // In progress: an ink band. Next: a thick frame. Neither borrows a colour a competitor may wear.
    final (band, onBand) = inProgress
        ? (scheme.inverseSurface, scheme.onInverseSurface)
        : (scheme.surfaceContainerLow, scheme.onSurface);
    final group = board.groups.where((g) => g.id == match.groupId).firstOrNull;
    void open() => _open(context, match, readOnly);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: inProgress
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.m),
              side: BorderSide(color: scheme.onSurface, width: 3),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: band,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.l,
                vertical: AppSpacing.s,
              ),
              child: Row(
                spacing: AppSpacing.s,
                children: [
                  Icon(
                    inProgress ? Icons.play_arrow : Icons.star_outline,
                    color: onBand,
                    size: 20,
                  ),
                  Text(
                    inProgress ? l10n.matInProgress : l10n.matRecommended,
                    style: text.titleSmall?.copyWith(color: onBand),
                  ),
                ],
              ),
            ),
          ),
          if (!inProgress) const Divider(),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l,
              vertical: AppSpacing.s,
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.m,
              children: [
                _CornerLine(side: Side.red, fighter: match.red, large: true),
                _CornerLine(side: Side.blue, fighter: match.blue, large: true),
              ],
            ),
            onTap: open,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              0,
              AppSpacing.l,
              AppSpacing.l,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.m,
              children: [
                if (group != null)
                  Text(
                    match.inReview
                        ? l10n.matInReview
                        : l10n.matGroupHeader(group.number, group.categoryName),
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                FilledButton(
                  onPressed: open,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: Text(
                    readOnly
                        ? l10n.matWatch
                        : inProgress
                        ? l10n.matBackToScoreboard
                        : l10n.matOpenScoreboard,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _open(BuildContext context, BoardMatch match, bool readOnly) => context
    .push(readOnly ? '/club/matches/${match.id}' : '/matches/${match.id}');

/// Matches as rows on one sheet: group, red and blue, and why one waits.
class _MatchList extends StatelessWidget {
  const _MatchList({
    required this.board,
    required this.matches,
    required this.readOnly,
  });

  final MatBoard board;
  final List<BoardMatch> matches;
  final bool readOnly;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (final (i, m) in matches.indexed) ...[
          if (i > 0) const Divider(),
          _MatchRow(board: board, match: m, readOnly: readOnly),
        ],
      ],
    ),
  );
}

/// One that cannot start keeps readable colours with a lock and its reason, and does not open.
class _MatchRow extends StatelessWidget {
  const _MatchRow({
    required this.board,
    required this.match,
    required this.readOnly,
  });

  final MatBoard board;
  final BoardMatch match;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final finished = match.status == MatchStatus.finished;
    final waiting = match.status == MatchStatus.pending && !match.available;
    final locked = waiting && !readOnly;
    return ListTile(
      minTileHeight: AppSizes.scoreTouchTarget,
      leading: _GroupBadge(
        number: match.groupNumber,
        color: groupColor(board.groupIndex(match.groupId)),
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
              style: theme.textTheme.headlineSmall,
            )
          : Icon(locked ? Icons.lock_outline : Icons.chevron_right),
      onTap: locked ? null : () => _open(context, match, readOnly),
    );
  }
}

/// The corner's colour mark (with its name for screen readers) and the fighter.
/// [large]: the featured match, with the corner named in words too.
class _CornerLine extends StatelessWidget {
  const _CornerLine({
    required this.side,
    required this.fighter,
    this.large = false,
  });

  final Side side;
  final Fighter fighter;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final corner = side == Side.red ? l10n.cornerRed : l10n.cornerBlue;
    final color = side == Side.red ? CompetitorColor.red : CompetitorColor.blue;
    return Semantics(
      label: '$corner: ${fighter.label(l10n)}',
      excludeSemantics: true,
      child: large
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.m,
                children: [
                  _Mark(color: color.color, width: AppSpacing.s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          corner,
                          style: text.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        Text(fighter.label(l10n), style: text.titleLarge),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Row(
              spacing: AppSpacing.s,
              children: [
                _Mark(color: color.color, width: AppSpacing.m, height: 12),
                Expanded(child: Text(fighter.label(l10n))),
              ],
            ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.color, required this.width, this.height});

  final Color color;
  final double width;
  final double? height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.index, required this.group});

  final int index;
  final BoardGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
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
                _GroupBadge(number: group.number, color: groupColor(index)),
                const SizedBox(width: AppSpacing.s),
                Flexible(
                  child: Text(
                    l10n.matGroupHeader(group.number, group.categoryName),
                    style: text.titleSmall,
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
                  child: Text(m.membersLine!, style: text.bodySmall),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The group's colour and number, as a small square tile.
class _GroupBadge extends StatelessWidget {
  const _GroupBadge({required this.number, required this.color});

  final int number;
  final CompetitorColor color;

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 36,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color.color,
      borderRadius: BorderRadius.circular(AppRadius.s),
    ),
    child: Text(
      '$number',
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(color: color.onColor),
    ),
  );
}
