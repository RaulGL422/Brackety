import 'dart:math';

import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/async_view.dart';
import '../../../core/keep_screen_on.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../control/control_ui.dart';
import '../../offline/ui/sync_status_icon.dart';
import '../../rulebook/rulebook_ui.dart';
import '../../scoreboard/data/match_view.dart';
import '../../scoreboard/ui/match_corrections.dart';
import '../data/mat_board.dart';
import '../state/mat_providers.dart';
import 'fighter_text.dart';
import '../../../core/up_button.dart';

/// The referee's mat: what to do now first (the match in progress, the next one), then
/// what comes later, what is finished and the groups on it.
/// With [readOnly] (the club) every match opens its timeline instead of the scoreboard.
/// The referee gets it through the device's queue and cache ([localBoardProvider]).
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
    final queued = !readOnly;
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
          leading: UpButton(label: l10n.eventsTitle, fallback: '/'),
          leadingWidth: UpButton.leadingWidth(context),
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
              // On a narrow phone the number must shrink, never be cut: it is what the referee checks.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  number == null ? '' : l10n.matTitle(number),
                  style: text.displaySmall?.copyWith(color: colors.onBand),
                ),
              ),
            ],
          ),
          actions: [
            if (board.value?.eventId case final eventId?)
              RulebookButton(eventId: eventId, color: colors.onBand),
            if (queued) const SyncStatusIcon(),
            if (readOnly)
              if (board.value case final b?
                  when b.eventId != null &&
                      b.mats.any((m) => m.id == matId && m.hasReferee))
                DisableMatButton(
                  eventId: b.eventId!,
                  matId: matId,
                  board: b,
                  color: colors.onBand,
                  onChanged: () => ref.invalidate(provider),
                ),
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
            Expanded(
              child: AsyncView(
                value: board,
                onRetry: () => ref.invalidate(provider),
                data: (board) => board.groups.isEmpty
                    ? Center(child: Text(l10n.matEmpty))
                    : RefreshIndicator(
                        onRefresh: () => ref.refresh(provider.future),
                        child: _BoardList(
                          board: board,
                          readOnly: readOnly,
                          // Club (control panel) and referee (move a match): after a change, the board again.
                          onControl: () => ref.invalidate(provider),
                        ),
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
  const _BoardList({
    required this.board,
    required this.readOnly,
    this.onControl,
  });

  final MatBoard board;
  final bool readOnly;

  /// Pending matches get a menu: the control panel's for the club, moving to another mat for
  /// the referee; groups only for the club.
  final VoidCallback? onControl;

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
    final busy = byStatus[MatchStatus.inProgress]!.isNotEmpty;
    // With a match in progress nothing is put forward: one match at a time on a mat.
    final others = byStatus[MatchStatus.pending]!
        .where((m) => busy || m.id != board.recommendedMatchId)
        .toList();
    final available = others.where((m) => m.available).toList();
    final waiting = others.where((m) => !m.available).toList();
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
          if (board.teamPool)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.m),
              child: Text(l10n.matTeamPoolNotice, style: text.bodySmall),
            ),
          if (board.offline)
            const _OfflineNotice()
          else if (busy)
            Text(l10n.matOneAtATime)
          else if (recommended == null)
            Text(l10n.matNoneAvailable)
          else
            _FeaturedMatch(
              board: board,
              match: recommended,
              readOnly: readOnly,
              onControl: onControl,
            ),
          if (available.isNotEmpty) ...[
            // With a match in progress none of them can start yet: not "available".
            section(busy ? l10n.matQueued : l10n.matPending),
            _MatchList(
              board: board,
              matches: available,
              readOnly: readOnly,
              onControl: onControl,
            ),
          ],
          if (waiting.isNotEmpty) ...[
            section(l10n.matWaitingTitle),
            _MatchList(
              board: board,
              matches: waiting,
              readOnly: readOnly,
              onControl: onControl,
            ),
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
              for (final g in board.groups)
                _GroupCard(
                  group: g,
                  control:
                      !readOnly || onControl == null || board.eventId == null
                      ? null
                      : _groupMenu(board, g, onControl!),
                ),
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

/// The menu of a pending match: the club's control panel, or the referee's move to another
/// mat (it needs network: the server checks the match is theirs). Null without the event.
Widget? _matchMenu(
  MatBoard board,
  BoardMatch match,
  bool readOnly,
  VoidCallback onChanged,
) {
  if (board.eventId == null) return null;
  return readOnly
      ? MatchControlMenu(
          eventId: board.eventId!,
          match: match,
          matNumber: board.matNumber,
          onChanged: onChanged,
        )
      : board.offline
      ? null
      : RefereeMoveMenu(board: board, match: match, onChanged: onChanged);
}

/// The club's menu of an individual group: groups of teams have no mat to change.
Widget? _groupMenu(MatBoard board, BoardGroup group, VoidCallback onChanged) {
  if (group.members.any((m) => m.teamNumber != null)) return null;
  final pending = [
    for (final m in board.matches)
      if (m.groupId == group.id && m.status == MatchStatus.pending) m,
  ];
  return GroupControlMenu(
    eventId: board.eventId!,
    group: group,
    pending: pending,
    matNumber: board.matNumber,
    onChanged: onChanged,
  );
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
class _FeaturedMatch extends ConsumerWidget {
  const _FeaturedMatch({
    required this.board,
    required this.match,
    required this.readOnly,
    this.inProgress = false,
    this.onControl,
  });

  final MatBoard board;
  final BoardMatch match;
  final bool readOnly;
  final bool inProgress;
  final VoidCallback? onControl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // In progress: an ink band. Next: a thick frame. Neither borrows a colour a competitor may wear.
    final (band, onBand) = inProgress
        ? (scheme.inverseSurface, scheme.onInverseSurface)
        : (scheme.surfaceContainerLow, scheme.onSurface);
    final group = board.groups.where((g) => g.id == match.groupId).firstOrNull;
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
                  Expanded(
                    child: Text(
                      inProgress ? l10n.matInProgress : l10n.matRecommended,
                      style: text.titleSmall?.copyWith(color: onBand),
                    ),
                  ),
                  if (!inProgress && onControl != null)
                    _matchMenu(board, match, readOnly, onControl!) ??
                        const SizedBox.shrink(),
                ],
              ),
            ),
          ),
          if (!inProgress) const Divider(),
          // No onTap: only the button opens it; tapping the names opened it by surprise.
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.l,
              vertical: AppSpacing.s,
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.m,
              children: [
                _CornerLine(
                  side: Side.red,
                  fighter: match.red,
                  corner: inProgress ? null : match.redCorner,
                  large: true,
                ),
                _CornerLine(
                  side: Side.blue,
                  fighter: match.blue,
                  corner: inProgress ? null : match.blueCorner,
                  large: true,
                ),
              ],
            ),
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
                if (!inProgress)
                  Text(l10n.matRecommendedWhy, style: text.bodyMedium),
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
                  onPressed: () => _open(context, match, readOnly),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: Text(
                    readOnly
                        ? l10n.matWatch
                        : inProgress
                        ? l10n.matBackToScoreboard
                        : l10n.matStartRecommended,
                  ),
                ),
                if (inProgress && !readOnly)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.block),
                    label: Text(l10n.cancelMatch),
                    onPressed: () => cancelMatch(context, ref, match.id),
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
    this.onControl,
  });

  final MatBoard board;
  final List<BoardMatch> matches;
  final bool readOnly;
  final VoidCallback? onControl;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (final (i, m) in matches.indexed) ...[
          if (i > 0) const Divider(),
          _MatchRow(
            board: board,
            match: m,
            readOnly: readOnly,
            onControl: onControl,
          ),
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
    this.onControl,
  });

  final MatBoard board;
  final BoardMatch match;
  final bool readOnly;
  final VoidCallback? onControl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final finished = match.status == MatchStatus.finished;
    final pending = match.status == MatchStatus.pending;
    final waiting = pending && !match.available;
    final locked = waiting && !readOnly;
    return ListTile(
      minTileHeight: AppSizes.scoreTouchTarget,
      leading: _GroupBadge(number: match.groupNumber),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CornerLine(
            side: Side.red,
            fighter: match.red,
            corner: pending ? match.redCorner : null,
          ),
          _CornerLine(
            side: Side.blue,
            fighter: match.blue,
            corner: pending ? match.blueCorner : null,
          ),
        ],
      ),
      subtitle: match.inReview
          ? Text(l10n.matInReview)
          : waiting ||
                match.waitReason == WaitReason.otherMat ||
                match.waitReason == WaitReason.reserved
          ? Text(waitText(context, match))
          : pending && match.plannedAt != null
          ? Text(
              l10n.matPlannedAt(
                DateFormat.Hm(Localizations.localeOf(context).toLanguageTag())
                    .format(match.plannedAt!.toLocal()),
              ),
            )
          : null,
      trailing: finished
          ? Text(
              '${match.redScore} - ${match.blueScore}',
              style: theme.textTheme.headlineSmall,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pending && onControl != null)
                  ?_matchMenu(board, match, readOnly, onControl!),
                Icon(locked ? Icons.lock_outline : Icons.chevron_right),
              ],
            ),
      onTap: locked ? null : () => _open(context, match, readOnly),
    );
  }
}

/// Why [match] cannot start yet, for its row.
String waitText(BuildContext context, BoardMatch match) {
  final l10n = AppLocalizations.of(context);
  return switch (match.waitReason) {
    WaitReason.review => l10n.matInReview,
    WaitReason.afterIndividual => l10n.matAfterIndividual,
    WaitReason.resting when match.readyAt != null => l10n.matResting(
      DateFormat.Hms(Localizations.localeOf(context).toLanguageTag())
          .format(match.readyAt!.toLocal()),
    ),
    WaitReason.otherMat when match.otherMatNumber != null =>
      l10n.matProposedElsewhere(match.otherMatNumber!),
    WaitReason.reserved when match.otherMatNumber != null =>
      l10n.matReservedElsewhere(match.otherMatNumber!),
    _ when match.pool && match.waitReason == null => l10n.matPoolOffline,
    _ => l10n.matWaiting,
  };
}

/// Where a pending fighter is now, in one short line; null when they are free with nothing else.
String? cornerText(BuildContext context, CornerState? state) {
  if (state == null) return null;
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).toLanguageTag();
  final freeAt = state.freeAt?.toLocal();
  final parts = [
    if (state.fightingOnMat != null)
      // Past the estimate (a long match): only where.
      freeAt == null
          ? l10n.cornerFightingNow(state.fightingOnMat!)
          : l10n.cornerFighting(
              state.fightingOnMat!,
              DateFormat.Hm(locale).format(freeAt),
            )
    else if (freeAt != null)
      l10n.cornerResting(DateFormat.Hms(locale).format(freeAt)),
    if (state.pendingMats.isNotEmpty)
      l10n.cornerPending(
        state.pendingMats.length,
        state.pendingMats.toSet().join(', '),
      ),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// The corner's colour mark (with its name for screen readers) and the fighter: a team by its
/// title with its people below, to call them, and for a pending match where they are now.
/// [large]: the featured match, with the corner named in words too.
class _CornerLine extends StatelessWidget {
  const _CornerLine({
    required this.side,
    required this.fighter,
    this.corner,
    this.large = false,
  });

  final Side side;
  final Fighter fighter;
  final CornerState? corner;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final corner = side == Side.red ? l10n.cornerRed : l10n.cornerBlue;
    final color = side == Side.red ? CompetitorColor.red : CompetitorColor.blue;
    final members = fighter.membersLine;
    final where = cornerText(context, this.corner);
    final details = [
      if (members != null)
        Text(
          members,
          style: (large ? text.bodyLarge : text.bodySmall)?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      if (where != null)
        Text(
          where,
          style: (large ? text.bodyMedium : text.bodySmall)?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
    ];
    return Semantics(
      label: ['$corner: ${fighter.label(l10n)}', ?members, ?where].join('. '),
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
                        ...details,
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.s,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _Mark(
                    color: color.color,
                    width: AppSpacing.m,
                    height: 12,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fighter.label(l10n),
                        style: fighter.teamNumber == null
                            ? null
                            : const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...details,
                    ],
                  ),
                ),
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
  const _GroupCard({required this.group, this.control});

  final BoardGroup group;

  /// The club's menu for the group, or null.
  final Widget? control;

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
                _GroupBadge(number: group.number),
                const SizedBox(width: AppSpacing.s),
                Flexible(
                  child: Text(
                    l10n.matGroupHeader(group.number, group.categoryName),
                    style: text.titleSmall,
                  ),
                ),
                ?control,
              ],
            ),
            if (group.createdBy != null)
              Text(
                l10n.groupCreatedBy(group.createdBy!),
                style: text.bodySmall,
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
/// The group's number in ink: a colour here could be taken for a competitor's.
class _GroupBadge extends StatelessWidget {
  const _GroupBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(AppRadius.s),
      ),
      child: Text(
        '$number',
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: scheme.onInverseSurface),
      ),
    );
  }
}
