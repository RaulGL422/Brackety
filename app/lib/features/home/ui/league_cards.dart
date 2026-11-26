import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../auth/state/auth_providers.dart';
import '../../events/data/my_event.dart';
import '../data/league_overview.dart';
import 'event_entry.dart';
import 'phase_rail.dart';

/// A league on now, on the ink band: the colour the design gives to «en curso».
class LiveCard extends StatelessWidget {
  const LiveCard({super.key, required this.league});

  final LeagueOverview league;

  // The band is ink in both themes: its content takes the dark theme's colours.
  @override
  Widget build(BuildContext context) => Theme(
    data: darkTheme(),
    child: _LiveBand(league: league),
  );
}

class _LiveBand extends StatelessWidget {
  const _LiveBand({required this.league});

  final LeagueOverview league;

  @override
  Widget build(BuildContext context) {
    final details = _details(context);
    final actions = _actions(context);
    // On a wide window the actions stand to the right instead of under a long empty band.
    final wide = WindowSize.of(context) == WindowSize.expanded;
    return Card(
      color: BracketyColors.of(context).band,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: wide
            ? Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: details,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  SizedBox(
                    width: 280,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: actions,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...details,
                  const SizedBox(height: AppSpacing.l),
                  ...actions,
                ],
              ),
      ),
    );
  }

  List<Widget> _details(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final event = league.featured;
    final tasks = event.isClub ? const <EventTask>[] : tasksOf(event);
    final matOnly = tasks.length == 1 && tasks.single == EventTask.mat;
    return [
      Row(
        children: [
          if (matOnly) ...[
            _MatTile(number: event.matNumber!),
            const SizedBox(width: AppSpacing.l),
          ],
          Expanded(
            child: _Heading(league: league, status: l10n.homeLiveToday),
          ),
        ],
      ),
      if (league.hasPhases) ...[
        const SizedBox(height: AppSpacing.m),
        _Rail(league: league),
        const SizedBox(height: AppSpacing.s),
        Text(
          l10n.homePhaseOf(event.phaseNumber, league.phases.last.phaseNumber),
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
      if (tasks.length > 1) ...[
        const SizedBox(height: AppSpacing.m),
        TaskChips(event: event, tasks: tasks),
      ],
    ];
  }

  List<Widget> _actions(BuildContext context) {
    final event = league.featured;
    return [
      EventEntry(league: league),
      if (event.isClub && league.hasPhases)
        TextButton(
          onPressed: () => context.push('/leagues/${event.id}'),
          child: Text(AppLocalizations.of(context).homeSeeLeague),
        ),
    ];
  }
}

/// A league whose next phase has not started: when it starts, and what can be done until then.
class UpcomingCard extends ConsumerWidget {
  const UpcomingCard({super.key, required this.league});

  final LeagueOverview league;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final event = league.featured;
    final date = DateFormat.MMMMd(locale).format(event.date);
    final today = ref.watch(todayProvider);
    final note = event.isClub
        ? DateUtils.isSameDay(event.date, today)
              ? l10n.homeClubNoteToday
              : l10n.homeClubNote(date)
        : event.matNumber != null && event.can(EventPermission.ownMat)
        ? l10n.homeMatNote(date)
        : null;
    final tasks = event.isClub ? const <EventTask>[] : tasksOf(event);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DateTile(date: event.date),
            const SizedBox(width: AppSpacing.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Heading(league: league),
                  if (league.hasPhases) ...[
                    const SizedBox(height: AppSpacing.m),
                    _Rail(league: league),
                  ],
                  if (tasks.length > 1) ...[
                    const SizedBox(height: AppSpacing.m),
                    TaskChips(event: event, tasks: tasks),
                  ],
                  if (note != null) ...[
                    const SizedBox(height: AppSpacing.m),
                    _Note(text: note),
                  ],
                  const SizedBox(height: AppSpacing.m),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: EventEntry(league: league),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The day of a coming event, large, as on a calendar page.
class DateTile extends StatelessWidget {
  const DateTile({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.onSurface, width: 2),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Semantics(
        label: DateFormat.yMMMMd(locale).format(date),
        excludeSemantics: true,
        child: Column(
          children: [
            Text(
              DateFormat.d(locale).format(date),
              style: theme.textTheme.headlineMedium?.copyWith(height: 1),
            ),
            Text(
              DateFormat.MMM(locale).format(date),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The league's name, who the account is in it and, on the band, that it is on now.
class _Heading extends StatelessWidget {
  const _Heading({required this.league, this.status});

  final LeagueOverview league;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = this.status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (status != null) ...[
          Row(
            children: [
              Icon(Icons.circle, size: 10, color: theme.colorScheme.onSurface),
              const SizedBox(width: AppSpacing.xs),
              Text(
                status,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Text(league.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          roleLine(AppLocalizations.of(context), league.featured),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.league});

  final LeagueOverview league;

  @override
  Widget build(BuildContext context) => PhaseRail(
    phases: league.phases,
    current: league.featured,
    onOpen: (phase) => _openerFor(context, phase),
  );

  VoidCallback? _openerFor(BuildContext context, MyEvent phase) {
    if (phase.isClub) return () => context.push('/events/${phase.id}/club');
    final tasks = tasksOf(phase);
    if (tasks.isEmpty) return null;
    if (tasks.length == 1) {
      return () => context.push(taskRoute(phase, tasks.single));
    }
    return () => chooseTask(context, phase, tasks);
  }
}

/// A referee's mat number, large: what they look for at the venue.
class _MatTile extends StatelessWidget {
  const _MatTile({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      width: 88,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.onSurface, width: 3),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Semantics(
        label: l10n.homeRoleRefereeMat(number),
        excludeSemantics: true,
        child: Column(
          children: [
            Text(l10n.homeMat, style: theme.textTheme.labelMedium),
            Text(
              '$number',
              style: theme.textTheme.displaySmall?.copyWith(height: 1),
            ),
          ],
        ),
      ),
    );
  }
}

/// When the next phase starts and what the account can do until then.
class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.schedule, size: 18),
            const SizedBox(width: AppSpacing.s),
            Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}
