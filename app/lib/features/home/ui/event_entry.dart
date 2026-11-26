import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../events/data/my_event.dart';
import '../data/league_overview.dart';

/// What opens the event, by role: the club its panel; a helper or referee their one task, or
/// «Entrar al evento» to choose among several (Raul, 2026-11-26).
class EventEntry extends StatelessWidget {
  const EventEntry({super.key, required this.league});

  final LeagueOverview league;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final event = league.featured;
    final live = event.phaseState == PhaseState.inProgress;
    if (event.isClub) {
      final label = switch ((live, league.hasPhases)) {
        (true, true) => l10n.homeOpenPhase(event.phaseNumber),
        (true, false) => l10n.homeOpenEvent,
        (false, true) => l10n.homePreparePhase(event.phaseNumber),
        (false, false) => l10n.homePrepareEvent,
      };
      return FilledButton(
        onPressed: () => context.push('/events/${event.id}/club'),
        child: Text(label),
      );
    }
    final tasks = tasksOf(event);
    if (tasks.isEmpty) return const _PendingTask();
    if (tasks.length == 1) {
      return FilledButton(
        onPressed: () => context.push(taskRoute(event, tasks.single)),
        child: Text(taskName(l10n, event, tasks.single)),
      );
    }
    return FilledButton(
      onPressed: () => chooseTask(context, event, tasks),
      child: Text(l10n.homeEnterEvent),
    );
  }
}

String taskName(AppLocalizations l10n, MyEvent event, EventTask task) =>
    switch (task) {
      EventTask.groups => l10n.eventMakeGroups,
      EventTask.panel => l10n.eventStaffPanel,
      EventTask.mat => l10n.homeOpenMyMat(event.matNumber!),
    };

/// Several tasks: the account picks one. What the event looks like inside comes later.
Future<void> chooseTask(
  BuildContext context,
  MyEvent event,
  List<EventTask> tasks,
) async {
  final l10n = AppLocalizations.of(context);
  final task = await showModalBottomSheet<EventTask>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: Semantics(
              header: true,
              child: Text(
                l10n.homeChooseTask,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          for (final task in tasks)
            ListTile(
              title: Text(taskName(l10n, event, task)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pop(task),
            ),
          const SizedBox(height: AppSpacing.l),
        ],
      ),
    ),
  );
  if (task != null && context.mounted) {
    await context.push(taskRoute(event, task));
  }
}

/// A helper's tasks as labels; past three, a count, so many permissions do not crowd the card.
class TaskChips extends StatelessWidget {
  const TaskChips({super.key, required this.event, required this.tasks});

  static const shown = 3;

  final MyEvent event;
  final List<EventTask> tasks;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final names = [for (final t in tasks) taskName(l10n, event, t)];
    final hidden = names.length - shown;
    return Semantics(
      label: '${l10n.homeTasks}: ${names.join(', ')}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.homeTasks,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final name in names.take(shown)) _Label(name),
              if (hidden > 0) _Label(l10n.homeTasksMore(hidden)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(AppRadius.s),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Who the account is in [event], in a few words. A place appears only once it is assigned.
String roleLine(AppLocalizations l10n, MyEvent event) {
  if (event.isClub) return l10n.homeRoleClub;
  if (event.roles.contains(EventRole.referee)) {
    final mat = event.matNumber;
    return mat == null ? l10n.homeRoleReferee : l10n.homeRoleRefereeMat(mat);
  }
  return l10n.homeRoleHelper;
}

/// A helper added to the event whose task the club has not chosen yet.
class _PendingTask extends StatelessWidget {
  const _PendingTask();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Wrap(
      spacing: AppSpacing.s,
      children: [
        Text(
          l10n.homeTask,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          l10n.homeTaskPending,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
