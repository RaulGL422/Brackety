import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../auth/data/api_error.dart';
import '../club/data/club_models.dart';
import '../club/state/club_providers.dart';
import '../mat/data/mat_board.dart';
import '../mat/ui/fighter_text.dart';
import 'control_repository.dart';

/// Runs one change of the control panel; says how it went. True if it was made.
Future<bool> runControl(
  BuildContext context,
  Future<void> Function() change,
) async {
  final l10n = AppLocalizations.of(context);
  final toasts = Toasts.of(context);
  try {
    await change();
    toasts.show(l10n.controlDone, kind: ToastKind.success);
    return true;
  } on DioException catch (e) {
    toasts.show(controlErrorText(l10n, e), kind: ToastKind.error);
    return false;
  }
}

String controlErrorText(AppLocalizations l10n, DioException e) =>
    switch (ApiError.from(e).code) {
      'MATCH_IN_PROGRESS' => l10n.controlMatchInProgress,
      'MATCH_NOT_PENDING' => l10n.controlMatchNotPending,
      'MAT_WITHOUT_REFEREE' => l10n.controlMatWithoutReferee,
      'ORDER_CHANGED' => l10n.controlOrderChanged,
      'TEAM_SIZE' => l10n.controlTeamSize,
      'GROUP_STARTED' => l10n.controlGroupStarted,
      'SAME_FIGHTER' => l10n.controlSameFighter,
      'MATCH_IN_REVIEW' => l10n.controlMatInReview,
      'NO_OTHER_MAT' => l10n.controlNoOtherMat,
      _ => l10n.controlError,
    };

/// A mat with a referee other than [current]; null if cancelled.
Future<MatOverview?> pickMat(
  BuildContext context,
  WidgetRef ref,
  String eventId, {
  int? current,
}) async {
  final l10n = AppLocalizations.of(context);
  final mats = (await ref.read(matsOverviewProvider(eventId).future))
      .where((m) => m.referee != null && m.number != current)
      .toList();
  if (!context.mounted) return null;
  return showDialog<MatOverview>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l10n.controlPickMat),
      children: [
        if (mats.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Text(l10n.controlNoOtherMat),
          ),
        for (final m in mats)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, m),
            child: Text(
              l10n.controlMatOption(m.number, m.referee!, m.pendingMatches),
            ),
          ),
      ],
    ),
  );
}

/// For the referee, on a pending match of their mat: send it to another mat with a referee.
class RefereeMoveMenu extends ConsumerWidget {
  const RefereeMoveMenu({
    super.key,
    required this.board,
    required this.match,
    required this.onChanged,
  });

  final MatBoard board;
  final BoardMatch match;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<bool>(
      tooltip: l10n.controlMenu,
      icon: const Icon(Icons.more_vert),
      itemBuilder: (_) => [
        PopupMenuItem(value: true, child: Text(l10n.controlMoveMatch)),
      ],
      onSelected: (_) async {
        final mats = board.mats
            .where((m) => m.hasReferee && m.number != board.matNumber)
            .toList();
        final mat = await showDialog<MatChoice>(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text(l10n.controlPickMat),
            children: [
              if (mats.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Text(l10n.controlNoOtherMat),
                ),
              for (final m in mats)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, m),
                  child: Text(l10n.matTitle(m.number)),
                ),
            ],
          ),
        );
        if (mat == null || !context.mounted) return;
        if (await runControl(
          context,
          () => ref
              .read(controlRepositoryProvider)
              .moveAsReferee(match.id, mat.id),
        )) {
          onChanged();
        }
      },
    );
  }
}

enum _MatchChoice { move, waiveRest }

/// For the club, on a pending match of a mat: move it to another mat (individual only) or let it
/// start without the least rest.
class MatchControlMenu extends ConsumerWidget {
  const MatchControlMenu({
    super.key,
    required this.eventId,
    required this.match,
    required this.matNumber,
    required this.onChanged,
  });

  final String eventId;
  final BoardMatch match;
  final int matNumber;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<_MatchChoice>(
      tooltip: l10n.controlMenu,
      icon: const Icon(Icons.more_vert),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _MatchChoice.move,
          child: Text(l10n.controlMoveMatch),
        ),
        PopupMenuItem(
          value: _MatchChoice.waiveRest,
          child: Text(l10n.controlWaiveRest),
        ),
      ],
      onSelected: (choice) async {
        final repository = ref.read(controlRepositoryProvider);
        switch (choice) {
          case _MatchChoice.move:
            final mat = await pickMat(
              context,
              ref,
              eventId,
              current: matNumber,
            );
            if (mat == null || !context.mounted) return;
            if (await runControl(
              context,
              () => repository.moveMatch(eventId, match.id, mat.id),
            )) {
              onChanged();
            }
          case _MatchChoice.waiveRest:
            final sure = await _confirm(
              context,
              l10n.controlWaiveRestTitle,
              l10n.controlWaiveRestBody(
                match.red.label(l10n),
                match.blue.label(l10n),
              ),
            );
            if (!sure || !context.mounted) return;
            if (await runControl(
              context,
              () => repository.waiveRest(eventId, match.id),
            )) {
              onChanged();
            }
        }
      },
    );
  }
}

/// For the club, on a mat with a referee: put it out of use. Each individual group with
/// pending matches goes to the mat chosen for it, or the one free first; it takes no more team
/// matches. A referee in the settings puts it back.
class DisableMatButton extends ConsumerWidget {
  const DisableMatButton({
    super.key,
    required this.eventId,
    required this.matId,
    required this.board,
    required this.onChanged,
    this.color,
  });

  final String eventId;
  final String matId;
  final MatBoard board;
  final VoidCallback onChanged;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      tooltip: l10n.controlDisableMat,
      icon: Icon(Icons.block, color: color),
      onPressed: () async {
        final groupMats = await showDialog<Map<String, String>>(
          context: context,
          builder: (_) => _DisableMatDialog(board: board, matId: matId),
        );
        if (groupMats == null || !context.mounted) return;
        final toasts = Toasts.of(context);
        try {
          final done = await ref
              .read(controlRepositoryProvider)
              .disableMat(eventId, matId, groupMats);
          toasts.show(
            l10n.controlMatDisabled(done.groupsMoved, done.teamMatchesToPool),
            kind: ToastKind.success,
          );
          ref.invalidate(matsOverviewProvider(eventId));
          onChanged();
        } on DioException catch (e) {
          toasts.show(
            ApiError.from(e).code == 'MATCH_IN_PROGRESS'
                ? l10n.controlMatBusy
                : controlErrorText(l10n, e),
            kind: ToastKind.error,
          );
        }
      },
    );
  }
}

/// The individual groups of [board] with matches to play there: where each goes. Pops the
/// chosen mats (group id → mat id; Automatic ones left out), or null if cancelled.
class _DisableMatDialog extends StatefulWidget {
  const _DisableMatDialog({required this.board, required this.matId});

  final MatBoard board;
  final String matId;

  @override
  State<_DisableMatDialog> createState() => _DisableMatDialogState();
}

class _DisableMatDialogState extends State<_DisableMatDialog> {
  final _chosen = <String, String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final board = widget.board;
    final groups = [
      for (final g in board.groups)
        if (board.matches.any(
          (m) =>
              m.groupId == g.id && m.status == MatchStatus.pending && !m.pool,
        ))
          g,
    ];
    final mats = board.mats
        .where((m) => m.hasReferee && m.id != widget.matId)
        .toList();
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.controlDisableMatTitle(board.matNumber)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.m,
            children: [
              Text(l10n.controlDisableMatBody),
              if (mats.isEmpty) Text(l10n.controlNoOtherMat),
              if (mats.isNotEmpty)
                for (final g in groups)
                  DropdownButtonFormField<String?>(
                    initialValue: _chosen[g.id],
                    decoration: InputDecoration(
                      labelText: l10n.matGroupHeader(g.number, g.categoryName),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l10n.matAuto)),
                      for (final m in mats)
                        DropdownMenuItem(
                          value: m.id,
                          child: Text(l10n.matTitle(m.number)),
                        ),
                    ],
                    onChanged: (id) => setState(
                      () => id == null
                          ? _chosen.remove(g.id)
                          : _chosen[g.id] = id,
                    ),
                  ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: mats.isEmpty
              ? null
              : () => Navigator.pop(context, _chosen),
          child: Text(l10n.controlDisableMat),
        ),
      ],
    );
  }
}

enum _GroupChoice { move, reorder }

/// For the club, on an individual group of a mat: move it with its pending matches, or change
/// the order of those.
class GroupControlMenu extends ConsumerWidget {
  const GroupControlMenu({
    super.key,
    required this.eventId,
    required this.group,
    required this.pending,
    required this.matNumber,
    required this.onChanged,
  });

  final String eventId;
  final BoardGroup group;

  /// The group's pending matches, in their order.
  final List<BoardMatch> pending;
  final int matNumber;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<_GroupChoice>(
      tooltip: l10n.controlMenu,
      icon: const Icon(Icons.more_vert),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _GroupChoice.move,
          child: Text(l10n.controlMoveGroup),
        ),
        if (pending.length > 1)
          PopupMenuItem(
            value: _GroupChoice.reorder,
            child: Text(l10n.controlReorder),
          ),
      ],
      onSelected: (choice) async {
        final repository = ref.read(controlRepositoryProvider);
        switch (choice) {
          case _GroupChoice.move:
            final mat = await pickMat(
              context,
              ref,
              eventId,
              current: matNumber,
            );
            if (mat == null || !context.mounted) return;
            if (await runControl(
              context,
              () => repository.moveGroup(eventId, group.id, mat.id),
            )) {
              onChanged();
            }
          case _GroupChoice.reorder:
            final order = await showDialog<List<String>>(
              context: context,
              builder: (_) => _ReorderDialog(pending: pending),
            );
            if (order == null || !context.mounted) return;
            if (await runControl(
              context,
              () => repository.reorder(eventId, group.id, order),
            )) {
              onChanged();
            }
        }
      },
    );
  }
}

class _ReorderDialog extends StatefulWidget {
  const _ReorderDialog({required this.pending});

  final List<BoardMatch> pending;

  @override
  State<_ReorderDialog> createState() => _ReorderDialogState();
}

class _ReorderDialogState extends State<_ReorderDialog> {
  late final _order = [...widget.pending];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.controlReorder),
      content: SizedBox(
        width: 420,
        height: 64.0 * _order.length + 40,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.controlReorderHint),
            Expanded(
              child: ReorderableListView(
                buildDefaultDragHandles: true,
                onReorderItem: (from, to) => setState(() {
                  _order.insert(to, _order.removeAt(from));
                }),
                children: [
                  for (final (i, m) in _order.indexed)
                    ListTile(
                      key: ValueKey(m.id),
                      leading: Text('${i + 1}'),
                      title: Text(
                        '${m.red.label(l10n)} – ${m.blue.label(l10n)}',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, [for (final m in _order) m.id]),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

Future<bool> _confirm(BuildContext context, String title, String body) async {
  final l10n = AppLocalizations.of(context);
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.controlConfirm),
            ),
          ],
        ),
      ) ??
      false;
}
