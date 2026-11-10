import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/async_view.dart';
import '../../../core/reason_dialog.dart';
import '../../../core/run_action.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/events_api.dart';
import '../state/events_controller.dart';

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
              onPressed: event.groups.isEmpty
                  ? null
                  : () => _clear(context, ref),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.l),
        Text(l10n.eventMats, style: text.titleMedium),
        const SizedBox(height: AppSpacing.s),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            for (final mat in event.mats)
              Chip(
                label: Text(
                  mat.referee == null
                      ? l10n.eventMatNoReferee(mat.number)
                      : l10n.eventMatReferee(mat.number, mat.referee!),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.l),
        Text(l10n.eventGroups, style: text.titleMedium),
        const SizedBox(height: AppSpacing.s),
        if (event.groups.isEmpty) Text(l10n.eventNoGroups),
        for (final group in event.groups)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.m),
            child: _GroupCard(eventId: event.id, group: group),
          ),
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
  const _GroupCard({required this.eventId, required this.group});

  final String eventId;
  final AdminGroup group;

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
                Text(l10n.groupMat(group.matNumber)),
                TextButton.icon(
                  icon: const Icon(Icons.group_remove_outlined),
                  label: Text(l10n.groupDissolve),
                  onPressed: () => _dissolve(context, ref),
                ),
              ],
            ),
            const Divider(),
            for (final match in group.matches)
              _MatchRow(eventId: eventId, match: match),
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
  const _MatchRow({required this.eventId, required this.match});

  final String eventId;
  final AdminMatch match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    String side(AdminSide s) => s.name ?? l10n.matchTeam(s.teamNumber ?? 0);
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
              _Corner(color: CompetitorColor.red, name: side(match.red)),
              _Corner(color: CompetitorColor.blue, name: side(match.blue)),
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
