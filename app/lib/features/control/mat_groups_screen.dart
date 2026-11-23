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
/// under another; wider, one column each.
class MatGroupsScreen extends ConsumerWidget {
  const MatGroupsScreen({super.key, required this.eventId});

  final String eventId;

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
        0,
      ),
      child: Text(AppLocalizations.of(context).matGroupsDragHint),
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
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(AppSpacing.s),
            children: [
              for (final mat in mats)
                SizedBox(
                  width: 300,
                  child: SingleChildScrollView(child: column(mat)),
                ),
            ],
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
    return DragTarget<GroupCard>(
      onWillAcceptWithDetails: (d) =>
          !mat.disabled && !mat.groups.any((g) => g.id == d.data.id),
      onAcceptWithDetails: (d) => onMove(d.data, mat),
      builder: (context, candidates, _) => Container(
        margin: const EdgeInsets.all(AppSpacing.s),
        padding: const EdgeInsets.all(AppSpacing.s),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty
              ? scheme.primaryContainer
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.m),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.s,
          children: [
            Text(
              '${l10n.matTitle(mat.number)} · '
              '${mat.disabled ? l10n.matGroupsDisabled : mat.referee ?? l10n.matNoReferee}',
              style: text.titleMedium,
            ),
            if (mat.finishedGroups > 0)
              Text(
                l10n.matGroupsFinished(mat.finishedGroups),
                style: text.bodySmall,
              ),
            if (candidates.isNotEmpty)
              Text(l10n.matGroupsDropHere(mat.number))
            else if (mat.groups.isEmpty)
              Text(
                l10n.matGroupsEmpty,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
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
      ),
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
    return LongPressDraggable<GroupCard>(
      data: group,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(AppRadius.m),
        child: SizedBox(width: 260, child: _GroupTile(group: group)),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: tile),
      child: tile,
    );
  }
}

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
    final names = group.members
        .map((m) => m.ghost ? l10n.ghostOf(m.name) : m.name)
        .join(', ');
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          AppSpacing.s,
          0,
          AppSpacing.s,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xs,
                children: [
                  Text(
                    l10n.matGroupsGroup(group.number, group.categoryName),
                    style: text.titleSmall,
                  ),
                  Text(names),
                  Text(
                    group.inProgress
                        ? '${l10n.matGroupsProgress(group.played, group.matches)}'
                              ' · ${l10n.matGroupsInProgress}'
                        : l10n.matGroupsProgress(group.played, group.matches),
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (onMove != null) _moveMenu(l10n),
          ],
        ),
      ),
    );
  }

  Widget _moveMenu(AppLocalizations l10n) => PopupMenuButton<MatGroups>(
    tooltip: l10n.matGroupsMoveGroup(group.number),
    icon: const Icon(Icons.drive_file_move_outline),
    enabled: !group.inProgress && targets.isNotEmpty,
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
