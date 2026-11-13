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
import '../../club/ui/participant_record_sheet.dart';
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
            // The league's own screen: every phase the account runs opens its panel.
            trailing: clubPhases.contains(phase.eventId)
                ? const Icon(Icons.chevron_right)
                : null,
            onTap: clubPhases.contains(phase.eventId)
                ? () => context.push('/events/${phase.eventId}/club')
                : null,
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
            // Places count within each category, so each goes under its own heading.
            final byCategory = <String, List<LeagueStandingRow>>{};
            for (final r in rows) {
              byCategory
                  .putIfAbsent(r.categoryName ?? l10n.noCategory, () => [])
                  .add(r);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final MapEntry(key: name, value: people)
                    in byCategory.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.l,
                      AppSpacing.l,
                      AppSpacing.l,
                      AppSpacing.xs,
                    ),
                    child: Text(
                      l10n.leagueCategoryHeader(name, people.length),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  for (final r in people)
                    _LeagueStandingTile(
                      row: r,
                      phaseNumbers: standings.phaseNumbers,
                    ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LeagueStandingTile extends StatelessWidget {
  const _LeagueStandingTile({required this.row, required this.phaseNumbers});

  final LeagueStandingRow row;
  final List<int> phaseNumbers;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final perPhase = [
      for (final (i, p) in row.phasePoints.indexed)
        p == null
            ? l10n.leaguePhaseAbsent(phaseNumbers[i])
            : l10n.leaguePhasePoints(
                phaseNumbers[i],
                p.attendance + p.matches,
                p.attendance,
                p.matches,
              ),
    ];
    final medal = row.medal;
    // With 0 points nobody has earned a place: before the first match everyone would share a meaningless "1".
    final ranked = row.total > 0;
    final metal = medal == null ? null : medalColor(medal);
    return ListTile(
      leading: Tooltip(
        message: medal != null
            ? medalName(l10n, medal)
            : ranked
            ? ''
            : l10n.leagueNoPoints,
        child: CircleAvatar(
          backgroundColor: metal,
          foregroundColor: metal == null ? null : Colors.black,
          child: Text(
            ranked ? '${row.position}' : '–',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      title: Text('${row.firstName} ${row.lastName}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text([?row.organizationName, ...perPhase].join('\n')),
          if (row.warnings > 0 || row.disqualifications > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.xs,
                children: [
                  if (row.warnings > 0)
                    _DisciplineBadge(
                      icon: Icons.warning_amber_rounded,
                      label: l10n.recordWarnings(row.warnings),
                      serious: false,
                    ),
                  if (row.disqualifications > 0)
                    _DisciplineBadge(
                      icon: Icons.block,
                      label: l10n.leagueDisqualifications(
                        row.disqualifications,
                      ),
                      serious: true,
                    ),
                ],
              ),
            ),
        ],
      ),
      isThreeLine: true,
      // The record of their latest phase: matches, points, warnings.
      onTap: row.eventId == null || row.participantId == null
          ? null
          : () => showParticipantRecord(
              context,
              eventId: row.eventId!,
              participantId: row.participantId!,
              name: '${row.firstName} ${row.lastName}',
            ),
      trailing: Text(
        l10n.standingsTotal(row.total),
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}

/// Warnings (amber) or disqualifications (red) of a person in the league, hard to miss.
class _DisciplineBadge extends StatelessWidget {
  const _DisciplineBadge({
    required this.icon,
    required this.label,
    required this.serious,
  });

  final IconData icon;
  final String label;
  final bool serious;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (fill, ink) = serious
        ? (scheme.errorContainer, scheme.onErrorContainer)
        : (const Color(0xFFFFE8B3), const Color(0xFF5C3B00));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s,
          vertical: 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.xs,
          children: [
            Icon(icon, size: 16, color: ink),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: ink, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
