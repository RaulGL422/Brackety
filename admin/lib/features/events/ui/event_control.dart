import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/run_action.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/data/admin_api_error.dart';
import '../data/events_api.dart';
import '../state/events_controller.dart';
import 'event_detail_view.dart';

/// The control panel's own messages for the errors the server names.
String? controlError(AppLocalizations l10n, AdminApiError error) =>
    switch (error.code) {
      'MATCH_IN_PROGRESS' => l10n.controlMatchInProgress,
      'MATCH_NOT_PENDING' => l10n.controlMatchNotPending,
      'MAT_WITHOUT_REFEREE' => l10n.controlMatWithoutReferee,
      'ORDER_CHANGED' => l10n.controlOrderChanged,
      'TEAM_SIZE' => l10n.controlTeamSize,
      'GROUP_STARTED' => l10n.controlGroupStarted,
      'SAME_FIGHTER' => l10n.controlSameFighter,
      _ => null,
    };

Future<void> _control(BuildContext context, Future<void> Function() change) {
  final l10n = AppLocalizations.of(context);
  return runAction(
    context,
    change,
    done: (_) => l10n.controlDone,
    notFound: l10n.eventChanged,
    explain: (error) => controlError(l10n, error),
  );
}

/// A mat with a referee other than [current]; null if cancelled.
Future<AdminMat?> _pickMat(
  BuildContext context,
  AdminEventDetail event, {
  int? current,
}) {
  final l10n = AppLocalizations.of(context);
  final mats = event.mats
      .where((m) => m.referee != null && m.number != current)
      .toList();
  return showDialog<AdminMat>(
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
              l10n.controlMatOption(m.number, m.referee!, m.plan.length),
            ),
          ),
      ],
    ),
  );
}

enum _MatchChoice { move, waiveRest }

/// On a pending match: move it to another mat (individual only), or let it start without the
/// least rest.
class MatchControlMenu extends ConsumerWidget {
  const MatchControlMenu({
    super.key,
    required this.event,
    required this.group,
    required this.match,
  });

  final AdminEventDetail event;
  final AdminGroup group;
  final AdminMatch match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(eventDetailProvider(event.id).notifier);
    return PopupMenuButton<_MatchChoice>(
      tooltip: l10n.controlMenu,
      icon: const Icon(Icons.more_vert),
      itemBuilder: (_) => [
        if (group.matNumber != null)
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
        switch (choice) {
          case _MatchChoice.move:
            final mat = await _pickMat(
              context,
              event,
              current: group.matNumber,
            );
            if (mat == null || !context.mounted) return;
            await _control(
              context,
              () => controller.moveMatch(match.id, mat.id),
            );
          case _MatchChoice.waiveRest:
            final sure = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                scrollable: true,
                title: Text(l10n.controlWaiveRestTitle),
                content: Text(
                  l10n.controlWaiveRestBody(
                    sideName(l10n, match.red),
                    sideName(l10n, match.blue),
                  ),
                ),
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
            );
            if (sure != true || !context.mounted) return;
            await _control(context, () => controller.waiveRest(match.id));
        }
      },
    );
  }
}

/// On an individual group: move it with its pending matches, or reorder those.
class GroupControlButtons extends ConsumerWidget {
  const GroupControlButtons({
    super.key,
    required this.event,
    required this.group,
  });

  final AdminEventDetail event;
  final AdminGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(eventDetailProvider(event.id).notifier);
    final pending = [
      for (final m in group.matches)
        if (m.status == AdminMatchStatus.pending) m,
    ];
    return Wrap(
      spacing: AppSpacing.s,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.swap_horiz),
          label: Text(l10n.controlMoveGroup),
          onPressed: () async {
            final mat = await _pickMat(
              context,
              event,
              current: group.matNumber,
            );
            if (mat == null || !context.mounted) return;
            await _control(
              context,
              () => controller.moveGroup(group.id, mat.id),
            );
          },
        ),
        if (pending.length > 1)
          TextButton.icon(
            icon: const Icon(Icons.low_priority),
            label: Text(l10n.controlReorder),
            onPressed: () async {
              final order = await showDialog<List<String>>(
                context: context,
                builder: (_) => _ReorderDialog(pending: pending),
              );
              if (order == null || !context.mounted) return;
              await _control(
                context,
                () => controller.reorder(group.id, order),
              );
            },
          ),
      ],
    );
  }
}

class _ReorderDialog extends StatefulWidget {
  const _ReorderDialog({required this.pending});

  final List<AdminMatch> pending;

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
        width: 480,
        height: 64.0 * _order.length + 40,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.controlReorderHint),
            Expanded(
              child: ReorderableListView(
                onReorderItem: (from, to) => setState(() {
                  _order.insert(to, _order.removeAt(from));
                }),
                children: [
                  for (final (i, m) in _order.indexed)
                    ListTile(
                      key: ValueKey(m.id),
                      leading: Text('${i + 1}'),
                      title: Text(
                        '${sideName(l10n, m.red)} – ${sideName(l10n, m.blue)}',
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
          child: Text(l10n.controlSave),
        ),
      ],
    );
  }
}

/// The real teams, with a button to move one of their people to another team of the category
/// while their group has not started.
class TeamsControl extends ConsumerWidget {
  const TeamsControl({super.key, required this.event});

  final AdminEventDetail event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final team in event.teams)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.controlTeamTitle(team.number, team.category)),
            subtitle: Text(
              [
                team.members
                    .map((m) => m.ghost ? l10n.ghostName(m.name) : m.name)
                    .join(', '),
                if (team.groupNumber != null)
                  team.groupStarted
                      ? l10n.controlTeamGroupStarted(team.groupNumber!)
                      : l10n.controlTeamInGroup(team.groupNumber!),
              ].join(' · '),
            ),
            trailing: team.groupStarted
                ? null
                : IconButton(
                    tooltip: l10n.controlMoveMember,
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: () => _move(context, ref, team),
                  ),
          ),
      ],
    );
  }

  Future<void> _move(
    BuildContext context,
    WidgetRef ref,
    AdminTeam team,
  ) async {
    final l10n = AppLocalizations.of(context);
    final person = await showDialog<AdminTeamPerson>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.controlMoveMemberWho),
        children: [
          for (final m in team.members)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, m),
              child: Text(m.name),
            ),
        ],
      ),
    );
    if (person == null || !context.mounted) return;
    final to = await showDialog<AdminTeam>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.controlMoveMemberTo),
        children: [
          for (final t in event.teams)
            if (t.id != team.id &&
                t.category == team.category &&
                !t.groupStarted)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, t),
                child: Text(
                  '${l10n.controlTeamTitle(t.number, t.category)} · '
                  '${t.members.map((m) => m.name).join(', ')}',
                ),
              ),
        ],
      ),
    );
    if (to == null || !context.mounted) return;
    await _control(
      context,
      () => ref
          .read(eventDetailProvider(event.id).notifier)
          .moveTeamMember(
            participantId: person.participantId,
            fromTeamId: team.id,
            toTeamId: to.id,
          ),
    );
  }
}
