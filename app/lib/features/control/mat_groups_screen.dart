import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/async_view.dart';
import '../../core/up_button.dart';
import '../../l10n/gen/app_localizations.dart';
import 'control_repository.dart';
import 'control_ui.dart';
import 'mat_groups.dart';

/// Every mat with its groups still to finish and who is in them (GR-4). A group moves by dragging
/// it onto another mat or with "Move to…" (the one-tap way, WCAG 2.5.7). On a phone the mats go one
/// under another; wider, one column each, sharing the width.
class MatGroupsScreen extends ConsumerWidget {
  const MatGroupsScreen({super.key, required this.eventId});

  final String eventId;

  /// A column never narrower than a group's names nor so wide that they float.
  static const _minColumn = 280.0;
  static const _maxColumn = 360.0;

  Future<void> _move(
    BuildContext context,
    WidgetRef ref,
    GroupCard group,
    MatGroups to,
  ) async {
    final repository = ref.read(controlRepositoryProvider);
    if (await runControl(
      context,
      () => repository.moveGroup(eventId, group.id, to.matId),
    )) {
      ref.invalidate(matGroupsProvider(eventId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = matGroupsProvider(eventId);
    final compact = WindowSize.of(context) == WindowSize.compact;
    return Scaffold(
      appBar: AppBar(
        leading: UpButton(
          label: l10n.back,
          isPlace: false,
          fallback: '/events/$eventId/club',
        ),
        leadingWidth: UpButton.leadingWidth(context),
        title: Text(l10n.matGroupsTitle),
      ),
      body: AsyncView(
        value: ref.watch(provider),
        onRetry: () => ref.invalidate(provider),
        data: (mats) => _board(context, ref, mats, compact: compact),
      ),
    );
  }

  Widget _board(
    BuildContext context,
    WidgetRef ref,
    List<MatGroups> mats, {
    required bool compact,
  }) {
    Widget column(MatGroups mat) => _MatColumn(
      mat: mat,
      mats: mats,
      onMove: (group, to) => _move(context, ref, group, to),
    );
    final hint = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.m,
        AppSpacing.l,
        AppSpacing.xs,
      ),
      child: Text(
        AppLocalizations.of(context).matGroupsDragHint,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
    if (compact) {
      return ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.l),
        children: [hint, for (final mat in mats) column(mat)],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        hint,
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width =
                  ((constraints.maxWidth - 2 * AppSpacing.s) / mats.length)
                      .clamp(_minColumn, _maxColumn);
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(AppSpacing.s),
                children: [
                  for (final mat in mats)
                    SizedBox(
                      width: width,
                      child: SingleChildScrollView(child: column(mat)),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A mat and its groups; a group dragged from another mat can be dropped on it, unless disabled.
class _MatColumn extends StatelessWidget {
  const _MatColumn({
    required this.mat,
    required this.mats,
    required this.onMove,
  });

  final MatGroups mat;
  final List<MatGroups> mats;
  final void Function(GroupCard group, MatGroups to) onMove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muted = TextStyle(color: scheme.onSurfaceVariant);
    return DragTarget<GroupCard>(
      onWillAcceptWithDetails: (d) =>
          !mat.disabled && !mat.groups.any((g) => g.id == d.data.id),
      onAcceptWithDetails: (d) => onMove(d.data, mat),
      builder: (context, candidates, _) {
        final dropping = candidates.isNotEmpty;
        return Container(
          margin: const EdgeInsets.all(AppSpacing.s),
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.m),
            // Where it will land: a thick ink frame, never a colour a competitor may wear.
            border: Border.all(
              color: dropping ? scheme.primary : Colors.transparent,
              width: 3,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.m,
            children: [
              _MatHeader(mat: mat),
              if (dropping)
                Text(l10n.matGroupsDropHere(mat.number), style: text.titleSmall)
              else if (mat.groups.isEmpty)
                Text(l10n.matGroupsEmpty, style: muted),
              for (final group in mat.groups)
                _DraggableGroup(
                  group: group,
                  targets: [
                    for (final m in mats)
                      if (!m.disabled && m.matId != mat.matId) m,
                  ],
                  onMove: onMove,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// The mat's number large, as on the hall's signs, and below who referees it (or that it is out of use).
class _MatHeader extends StatelessWidget {
  const _MatHeader({required this.mat});

  final MatGroups mat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.matTitle(mat.number), style: text.headlineSmall),
        Row(
          spacing: AppSpacing.xs,
          children: [
            Icon(
              mat.disabled ? Icons.block : Icons.sports,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
            Flexible(
              child: Text(
                mat.disabled
                    ? l10n.matGroupsDisabled
                    : mat.referee ?? l10n.matNoReferee,
                style: muted,
              ),
            ),
          ],
        ),
        if (mat.finishedGroups > 0)
          Text(l10n.matGroupsFinished(mat.finishedGroups), style: muted),
      ],
    );
  }
}

/// Held down, a group not fighting now lifts and follows the finger.
class _DraggableGroup extends StatelessWidget {
  const _DraggableGroup({
    required this.group,
    required this.targets,
    required this.onMove,
  });

  final GroupCard group;
  final List<MatGroups> targets;
  final void Function(GroupCard group, MatGroups to) onMove;

  @override
  Widget build(BuildContext context) {
    final tile = _GroupTile(group: group, targets: targets, onMove: onMove);
    if (group.inProgress) return tile;
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: LongPressDraggable<GroupCard>(
        data: group,
        feedback: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(AppRadius.m),
          child: SizedBox(width: 260, child: _GroupTile(group: group)),
        ),
        childWhenDragging: Opacity(opacity: 0.4, child: tile),
        child: tile,
      ),
    );
  }
}

/// A group: its number in an ink square (groups are told apart by number, not by colour), its
/// category, one name per line and how far it has gone. Fighting now, an ink band says it stays.
class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group, this.targets = const [], this.onMove});

  final GroupCard group;

  /// Where "Move to…" may send it; empty in the dragged copy.
  final List<MatGroups> targets;
  final void Function(GroupCard group, MatGroups to)? onMove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = BracketyColors.of(context);
    return Semantics(
      container: true,
      label: l10n.matGroupsGroup(group.number, group.categoryName),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          side: group.inProgress
              ? BorderSide(color: colors.band, width: 2)
              : BorderSide(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (group.inProgress)
              Container(
                color: colors.band,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.m,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  spacing: AppSpacing.s,
                  children: [
                    Icon(Icons.timer_outlined, size: 18, color: colors.onBand),
                    Flexible(
                      child: Text(
                        l10n.matGroupsInProgress,
                        style: text.labelLarge?.copyWith(color: colors.onBand),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                AppSpacing.m,
                AppSpacing.xs,
                AppSpacing.m,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.s,
                children: [
                  Row(
                    spacing: AppSpacing.m,
                    children: [
                      _NumberSquare(number: group.number),
                      Expanded(
                        child: Text(
                          group.categoryName,
                          style: text.titleMedium,
                        ),
                      ),
                      if (onMove != null && !group.inProgress) _moveMenu(l10n),
                    ],
                  ),
                  // The names whole, one per line: who is where is what this screen is for.
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.s),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final m in group.members)
                          Text(m.ghost ? l10n.ghostOf(m.name) : m.name),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.matGroupsProgress(group.played, group.matches),
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moveMenu(AppLocalizations l10n) => PopupMenuButton<MatGroups>(
    tooltip: l10n.matGroupsMoveGroup(group.number),
    icon: const Icon(Icons.drive_file_move_outline),
    enabled: targets.isNotEmpty,
    itemBuilder: (_) => [
      for (final mat in targets)
        PopupMenuItem(
          value: mat,
          child: Text(
            '${l10n.matTitle(mat.number)} · ${mat.referee ?? l10n.matNoReferee}',
          ),
        ),
    ],
    onSelected: (mat) => onMove!(group, mat),
  );
}

/// The group's number on ink, large enough to find from across the table.
class _NumberSquare extends StatelessWidget {
  const _NumberSquare({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final colors = BracketyColors.of(context);
    return ExcludeSemantics(
      child: Container(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.band,
          borderRadius: BorderRadius.circular(AppRadius.s),
        ),
        child: Text(
          '$number',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(color: colors.onBand),
        ),
      ),
    );
  }
}
