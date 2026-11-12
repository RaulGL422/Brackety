import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/async_view.dart';
import '../../../core/medal.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../club/data/club_repository.dart';
import '../../club/ui/export_download.dart';
import '../../events/state/events_providers.dart';
import '../data/league_models.dart';
import '../state/league_providers.dart';
import 'league_settings_dialog.dart';
import 'new_phase_dialog.dart';

/// The league this phase belongs to: its phases, the accumulated standings and the podiums.
class LeagueTab extends ConsumerWidget {
  const LeagueTab({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = leagueProvider(eventId);
    return AsyncView(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      data: (league) => ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(eventId: eventId, league: league),
                  _Phases(eventId: eventId, league: league),
                  const Divider(height: AppSpacing.xl),
                  _Standings(eventId: eventId, league: league),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.eventId, required this.league});

  final String eventId;
  final League league;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final podium = league.podium;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.s,
      ),
      title: Text(league.name, style: Theme.of(context).textTheme.titleLarge),
      subtitle: Text(
        l10n.leaguePodiumSummary(podium.firsts, podium.seconds, podium.thirds),
      ),
      trailing: OutlinedButton.icon(
        icon: const Icon(Icons.edit_outlined),
        label: Text(l10n.leagueEdit),
        onPressed: () => showLeagueSettings(context, eventId, league),
      ),
    );
  }
}

class _Phases extends ConsumerWidget {
  const _Phases({required this.eventId, required this.league});

  final String eventId;
  final League league;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    // Only the phases this account runs as club can be opened.
    final clubPhases = {
      for (final p in ref.watch(clubPhasesProvider(eventId)).value ?? const [])
        p.id,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            AppSpacing.m,
            AppSpacing.l,
            AppSpacing.s,
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.m,
            runSpacing: AppSpacing.s,
            children: [
              Text(
                l10n.leaguePhases,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.leagueNewPhase),
                onPressed: () => showNewPhaseDialog(context, eventId, league),
              ),
            ],
          ),
        ),
        for (final phase in league.phases)
          ListTile(
            leading: CircleAvatar(child: Text('${phase.number}')),
            title: Text(phase.name),
            subtitle: Text(
              [
                DateFormat.yMMMMd(locale).format(phase.date),
                disciplineName(l10n, phase.discipline),
                l10n.leaguePhaseEntries(phase.participants),
              ].join(' · '),
            ),
            selected: phase.eventId == eventId,
            trailing: phase.eventId == eventId
                ? Text(l10n.leagueCurrentPhase)
                : const Icon(Icons.chevron_right),
            onTap:
                phase.eventId == eventId || !clubPhases.contains(phase.eventId)
                ? null
                : () => context.push('/events/${phase.eventId}/club'),
          ),
      ],
    );
  }
}

String disciplineName(AppLocalizations l10n, Discipline d) => switch (d) {
  Discipline.tambo => l10n.disciplineTambo,
  Discipline.ground => l10n.disciplineGround,
  Discipline.throws => l10n.disciplineThrows,
  Discipline.technicalExpression => l10n.disciplineTechnicalExpression,
};

/// Points per person added up over the phases, ranked by category, with the podium's medals.
class _Standings extends ConsumerStatefulWidget {
  const _Standings({required this.eventId, required this.league});

  final String eventId;
  final League league;

  @override
  ConsumerState<_Standings> createState() => _StandingsState();
}

class _StandingsState extends ConsumerState<_Standings> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = leagueStandingsProvider(widget.eventId);
    final categories = widget.league.categoryNames;
    final category = categories.contains(_category) ? _category : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          child: Wrap(
            spacing: AppSpacing.m,
            runSpacing: AppSpacing.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.leagueStandings,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              DropdownButton<String?>(
                value: category,
                items: [
                  DropdownMenuItem(child: Text(l10n.allCategories)),
                  for (final c in categories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (c) => setState(() => _category = c),
              ),
              // Downloads, like the phase's CSVs, only on the web.
              if (kIsWeb)
                TextButton.icon(
                  icon: const Icon(Icons.download_outlined),
                  label: Text(l10n.leagueStandingsCsv),
                  onPressed: () => downloadExport(
                    context,
                    ref,
                    widget.eventId,
                    EventExport.leagueStandings,
                  ),
                ),
            ],
          ),
        ),
        AsyncView(
          value: ref.watch(provider),
          onRetry: () => ref.invalidate(provider),
          data: (standings) {
            final rows = [
              for (final r in standings.rows)
                if (category == null || r.categoryName == category) r,
            ];
            if (rows.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Text(l10n.standingsEmpty, textAlign: TextAlign.center),
              );
            }
            return Column(
              children: [
                for (final r in rows)
                  _LeagueStandingTile(
                    row: r,
                    phaseNumbers: standings.phaseNumbers,
                    showCategory: category == null,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LeagueStandingTile extends StatelessWidget {
  const _LeagueStandingTile({
    required this.row,
    required this.phaseNumbers,
    required this.showCategory,
  });

  final LeagueStandingRow row;
  final List<int> phaseNumbers;
  final bool showCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final perPhase = [
      for (final (i, points) in row.phasePoints.indexed)
        l10n.leaguePhasePoints(
          phaseNumbers[i],
          points == null ? '–' : '$points',
        ),
    ].join('   ');
    final medal = row.medal;
    return ListTile(
      leading: CircleAvatar(child: Text('${row.position}')),
      title: Row(
        children: [
          Flexible(child: Text('${row.firstName} ${row.lastName}')),
          if (medal != null) ...[
            const SizedBox(width: AppSpacing.s),
            MedalIcon(medal: medal),
          ],
        ],
      ),
      subtitle: Text(
        [
          [
            if (showCategory) row.categoryName ?? l10n.noCategory,
            ?row.organizationName,
          ].join(' · '),
          perPhase,
        ].where((line) => line.isNotEmpty).join('\n'),
      ),
      isThreeLine: showCategory || row.organizationName != null,
      trailing: Text(
        l10n.standingsTotal(row.total),
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
