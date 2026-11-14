import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/async_view.dart';
import '../../../core/reason_dialog.dart';
import '../../../core/run_action.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/events_api.dart';
import '../state/events_controller.dart';
import 'event_control.dart';

/// An event's mats and groups, and the three things the superadmin can undo in it.
class EventDetailView extends ConsumerWidget {
  const EventDetailView({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(eventDetailProvider(eventId));
    final refresh = ref.read(eventDetailProvider(eventId).notifier).refresh;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l10n.eventBack,
              icon: const Icon(Icons.arrow_back),
              onPressed: ref.read(selectedEventProvider.notifier).close,
            ),
            Expanded(
              child: Text(
                detail.value?.name ?? '',
                style: Theme.of(context).textTheme.headlineSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: l10n.refresh,
              icon: const Icon(Icons.refresh),
              onPressed: refresh,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        Expanded(
          child: AsyncView(
            value: detail,
            onRetry: refresh,
            data: (event) => _Detail(event),
          ),
        ),
      ],
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail(this.event);

  final AdminEventDetail event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      children: [
        Wrap(
          spacing: AppSpacing.l,
          runSpacing: AppSpacing.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.eventDate(event.date)),
            Text(event.ownerEmail),
            Text(l10n.eventEntries(event.entries)),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
                side: BorderSide(color: scheme.error, width: 2),
              ),
              icon: const Icon(Icons.restart_alt),
              label: Text(l10n.competitionClear),
              // Teams without a group go too: they cannot be undone one by one.
              onPressed: event.groups.isEmpty && event.teams.isEmpty
                  ? null
                  : () => _clear(context, ref),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.l),
        Text(l10n.eventMats, style: text.titleMedium),
        const SizedBox(height: AppSpacing.s),
        for (final mat in event.mats) _MatPlan(mat: mat),
        const SizedBox(height: AppSpacing.l),
        Text(l10n.eventGroups, style: text.titleMedium),
        const SizedBox(height: AppSpacing.s),
        if (event.groups.isEmpty) Text(l10n.eventNoGroups),
        for (final group in event.groups)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.m),
            child: _GroupCard(event: event, group: group),
          ),
        if (event.teams.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.l),
          Text(l10n.controlTeams, style: text.titleMedium),
          TeamsControl(event: event),
        ],
      ],
    );
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final reason = await askReason(
      context,
      title: l10n.competitionClearTitle(event.name),
      body: l10n.competitionClearBody,
      confirmLabel: l10n.competitionClear,
      typeToConfirm: event.name,
    );
    if (reason == null || !context.mounted) return;
    await runAction(
      context,
      () => ref
          .read(eventDetailProvider(event.id).notifier)
          .clearCompetition(reason),
      done: (cleared) => l10n.competitionCleared(cleared.groups, cleared.teams),
      notFound: l10n.eventChanged,
    );
  }
}

class _GroupCard extends ConsumerWidget {
  const _GroupCard({required this.event, required this.group});

  final AdminEventDetail event;
  final AdminGroup group;

  String get eventId => event.id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppSpacing.m,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  l10n.groupTitle(group.number, group.category),
                  style: text.titleSmall,
                ),
                Text(
                  group.matNumber == null
                      ? l10n.groupPool
                      : l10n.groupMat(group.matNumber!),
                ),
                if (group.createdBy != null)
                  Text(l10n.groupCreatedBy(group.createdBy!)),
                TextButton.icon(
                  icon: const Icon(Icons.group_remove_outlined),
                  label: Text(l10n.groupDissolve),
                  onPressed: () => _dissolve(context, ref),
                ),
              ],
            ),
            // Groups of teams have no mat: their matches go to the free mats.
            if (group.matNumber != null)
              GroupControlButtons(event: event, group: group),
            Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.xs,
              children: [
                for (final member in group.members)
                  Chip(
                    avatar: member.ghost
                        ? const Icon(Icons.blur_on, size: 18)
                        : null,
                    label: Text(sideName(l10n, member)),
                  ),
              ],
            ),
            const Divider(),
            for (final match in group.matches)
              _MatchRow(event: event, group: group, match: match),
          ],
        ),
      ),
    );
  }

  Future<void> _dissolve(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final reason = await askReason(
      context,
      title: l10n.groupDissolveTitle(group.number),
      body: l10n.groupDissolveBody,
      confirmLabel: l10n.groupDissolve,
    );
    if (reason == null || !context.mounted) return;
    await runAction(
      context,
      () => ref
          .read(eventDetailProvider(eventId).notifier)
          .dissolveGroup(group.id, reason),
      done: (_) => l10n.groupDissolved(group.number),
      notFound: l10n.eventChanged,
    );
  }
}

class _MatchRow extends ConsumerWidget {
  const _MatchRow({
    required this.event,
    required this.group,
    required this.match,
  });

  final AdminEventDetail event;
  final AdminGroup group;
  final AdminMatch match;

  String get eventId => event.id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final status = match.inReview
        ? l10n.matchInReview
        : switch (match.status) {
            AdminMatchStatus.pending => l10n.matchPending,
            AdminMatchStatus.inProgress => l10n.matchInProgress,
            AdminMatchStatus.finished => l10n.matchFinished,
          };
    final fight = Row(
      spacing: AppSpacing.m,
      children: [
        SizedBox(
          width: 28,
          child: Text('${match.order + 1}', style: text.titleSmall),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Corner(
                color: CompetitorColor.red,
                name: sideName(l10n, match.red),
              ),
              _Corner(
                color: CompetitorColor.blue,
                name: sideName(l10n, match.blue),
              ),
            ],
          ),
        ),
        if (match.status != AdminMatchStatus.pending)
          Text('${match.redScore}–${match.blueScore}', style: text.titleMedium),
      ],
    );
    final reset = match.canReset
        ? TextButton(
            onPressed: () => _reset(context, ref),
            child: Text(l10n.matchReset),
          )
        : match.status == AdminMatchStatus.pending
        ? Align(
            alignment: AlignmentDirectional.centerEnd,
            child: MatchControlMenu(event: event, group: group, match: match),
          )
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      // Narrow: the status and the button go under the names, which keep the width.
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 520
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  fight,
                  Row(
                    children: [
                      const SizedBox(width: 28 + AppSpacing.m),
                      Expanded(child: Text(status)),
                      ?reset,
                    ],
                  ),
                ],
              )
            : Row(
                spacing: AppSpacing.m,
                children: [
                  Expanded(child: fight),
                  SizedBox(width: 96, child: Text(status)),
                  SizedBox(width: 112, child: reset),
                ],
              ),
      ),
    );
  }

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final reason = await askReason(
      context,
      title: l10n.matchResetTitle(match.order + 1),
      body: l10n.matchResetBody,
      confirmLabel: l10n.matchReset,
    );
    if (reason == null || !context.mounted) return;
    await runAction(
      context,
      () => ref
          .read(eventDetailProvider(eventId).notifier)
          .resetMatch(match.id, reason),
      done: (_) => l10n.matchResetDone,
      notFound: l10n.eventChanged,
    );
  }
}

/// "Ana Prueba", "Team 2 (Ana, Bea, Carla)"; a ghost (or ghost member) says so.
String sideName(AppLocalizations l10n, AdminSide side) {
  final name = side.name != null
      ? side.name!
      : side.members.isEmpty
      ? l10n.matchTeam(side.teamNumber ?? 0)
      : l10n.teamWithMembers(
          side.teamNumber ?? 0,
          side.members
              .map((m) => m.ghost ? l10n.ghostName(m.name) : m.name)
              .join(', '),
        );
  return side.ghost ? l10n.ghostName(name) : name;
}

/// A mat, its referee and, folded, the order its pending matches would come up in.
class _MatPlan extends StatelessWidget {
  const _MatPlan({required this.mat});

  final AdminMat mat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final text = Theme.of(context).textTheme;
    return Card(
      child: ExpansionTile(
        title: Text(
          mat.referee == null
              ? l10n.eventMatNoReferee(mat.number)
              : l10n.eventMatReferee(mat.number, mat.referee!),
        ),
        subtitle: Text(
          mat.plan.isEmpty
              ? l10n.planEmpty
              : l10n.planSummary(
                  mat.plan.length,
                  DateFormat.Hm(locale).format(mat.plan.first.startsAt),
                ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.m,
          0,
          AppSpacing.m,
          AppSpacing.m,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mat.plan.isNotEmpty) Text(l10n.planHint, style: text.bodySmall),
          for (final (i, p) in mat.plan.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.m,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text('${i + 1}', style: text.titleSmall),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(DateFormat.Hm(locale).format(p.startsAt)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.groupTitle(p.groupNumber, p.category),
                          style: text.bodySmall,
                        ),
                        _Corner(
                          color: CompetitorColor.red,
                          name: sideName(l10n, p.red),
                        ),
                        _Corner(
                          color: CompetitorColor.blue,
                          name: sideName(l10n, p.blue),
                        ),
                      ],
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

class _Corner extends StatelessWidget {
  const _Corner({required this.color, required this.name});

  final CompetitorColor color;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: AppSpacing.s,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
