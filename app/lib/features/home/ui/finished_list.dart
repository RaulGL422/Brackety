import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/league_overview.dart';
import 'event_entry.dart';

/// What is over, in short: the latest three, the rest on demand.
class FinishedList extends StatefulWidget {
  const FinishedList({super.key, required this.leagues});

  final List<LeagueOverview> leagues;

  @override
  State<FinishedList> createState() => _FinishedListState();
}

class _FinishedListState extends State<FinishedList> {
  static const shown = 3;
  var _all = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final leagues = widget.leagues;
    final visible = _all ? leagues : leagues.take(shown).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, league) in visible.indexed) ...[
                if (i > 0) const Divider(height: 1),
                _FinishedRow(league: league),
              ],
            ],
          ),
        ),
        if (leagues.length > shown)
          TextButton(
            onPressed: () => setState(() => _all = !_all),
            child: Text(
              _all
                  ? l10n.homeSeeFewerFinished
                  : l10n.homeSeeAllFinished(leagues.length),
            ),
          ),
      ],
    );
  }
}

class _FinishedRow extends StatelessWidget {
  const _FinishedRow({required this.league});

  final LeagueOverview league;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final event = league.featured;
    final tasks = event.isClub ? const <EventTask>[] : tasksOf(event);
    final VoidCallback? open = event.isClub
        ? () => context.push('/events/${event.id}/club')
        : tasks.isEmpty
        ? null
        : tasks.length == 1
        ? () => context.push(taskRoute(event, tasks.single))
        : () => chooseTask(context, event, tasks);
    return ListTile(
      enabled: open != null,
      onTap: open,
      leading: SizedBox(
        width: 56,
        child: Text(
          DateFormat.MMMd(locale).format(event.date),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      title: Text(league.name),
      subtitle: Text(
        league.hasPhases
            ? l10n.homeLeaguePhases(league.phases.length)
            : roleLine(l10n, event),
      ),
      trailing: open == null ? null : const Icon(Icons.chevron_right),
    );
  }
}
