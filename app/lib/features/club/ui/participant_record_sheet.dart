import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/async_view.dart';
import '../../../core/medal.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../mat/data/mat_board.dart';
import '../../scoreboard/ui/undo_text.dart';
import '../data/club_models.dart';
import '../state/club_providers.dart';
import '../../mat/ui/mat_label.dart';

/// A participant's day for the club: their place and points, their warnings (unfolding to each
/// one: match, minute, reason, referee) and each match with the rival, the score and how it ended.
/// A match opens its timeline. With [personId] (from the league) the warnings are those of every
/// phase of the league.
Future<void> showParticipantRecord(
  BuildContext context, {
  required String eventId,
  required String participantId,
  required String name,
  String? personId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.75,
    maxChildSize: 0.95,
    builder: (context, controller) => _RecordView(
      eventId: eventId,
      participantId: participantId,
      name: name,
      personId: personId,
      controller: controller,
    ),
  ),
);

class _RecordView extends ConsumerWidget {
  const _RecordView({
    required this.eventId,
    required this.participantId,
    required this.name,
    required this.controller,
    this.personId,
  });

  final String eventId;
  final String participantId;
  final String name;
  final String? personId;
  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final provider = participantRecordProvider((
      eventId: eventId,
      participantId: participantId,
    ));
    return AsyncView(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      data: (record) {
        final row = record.standing;
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            0,
            AppSpacing.l,
            AppSpacing.xl,
          ),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: PlaceBadge(place: row.position),
              title: Text(name, style: text.titleLarge),
              subtitle: Text(
                l10n.placeInCategory(
                  row.position,
                  row.categoryName ?? l10n.noCategory,
                  row.age,
                ),
              ),
            ),
            Text(
              l10n.recordTotals(
                row.attendancePoints,
                row.matchPoints,
                row.total,
              ),
              style: text.titleMedium,
            ),
            if (personId case final person?)
              _LeagueIncidents(eventId: eventId, personId: person)
            else
              _Incidents(phases: [(name: null, matches: record.matches)]),
            const SizedBox(height: AppSpacing.m),
            if (record.matches.isEmpty) Text(l10n.recordNoMatches),
            for (final m in record.matches) _MatchCard(match: m),
          ],
        );
      },
    );
  }
}

class _LeagueIncidents extends ConsumerWidget {
  const _LeagueIncidents({required this.eventId, required this.personId});

  final String eventId;
  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = leagueRecordProvider((
      eventId: eventId,
      personId: personId,
    ));
    return AsyncView(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      data: (league) => _Incidents(
        league: true,
        phases: [
          for (final p in league.phases)
            (name: l10n.recordPhase(p.number, p.name), matches: p.matches),
        ],
      ),
    );
  }
}

/// How many warnings next to the points; unfolded, each one (and a disqualification) with its
/// match, minute, reason and referee, under its phase's name when there is one.
class _Incidents extends StatelessWidget {
  const _Incidents({required this.phases, this.league = false});

  final List<({String? name, List<RecordMatch> matches})> phases;
  final bool league;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final all = [
      for (final p in phases)
        for (final m in p.matches) ...m.incidents,
    ];
    final warnings = all.where((i) => i.isWarning).length;
    final disqualifications = all.length - warnings;
    if (all.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.s),
        child: Text(
          league ? l10n.recordNoIncidentsLeague : l10n.recordNoIncidents,
        ),
      );
    }
    final summary = [
      league
          ? l10n.recordWarningsLeague(warnings)
          : l10n.recordWarnings(warnings),
      if (disqualifications > 0)
        l10n.leagueDisqualifications(disqualifications),
    ].join(' · ');
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: Icon(
        disqualifications > 0 ? Icons.block : Icons.warning_amber_rounded,
        color: disqualifications > 0
            ? Theme.of(context).colorScheme.error
            : BracketyColors.of(context).warning,
      ),
      title: Text(summary),
      subtitle: Text(l10n.recordIncidentsHint),
      children: [
        for (final p in phases)
          if (p.matches.any((m) => m.incidents.isNotEmpty)) ...[
            if (p.name != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s),
                  child: Text(
                    p.name!,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
            for (final m in p.matches)
              for (final i in m.incidents) _IncidentTile(match: m, incident: i),
          ],
      ],
    );
  }
}

class _IncidentTile extends StatelessWidget {
  const _IncidentTile({required this.match, required this.incident});

  final RecordMatch match;
  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final i = incident;
    final kind = switch (i.kind) {
      IncidentKind.warning => l10n.incidentWarning,
      IncidentKind.oneHandWarning => l10n.incidentOneHand,
      IncidentKind.disqualification => l10n.recordDisqualified,
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => context.push('/club/matches/${match.matchId}'),
      title: Text(
        [
          kind,
          clockText(i.clock),
          if (i.reason.isNotEmpty) i.reason,
        ].join(' · '),
      ),
      subtitle: Text(
        [
          l10n.recordVs(match.rival),
          l10n.recordWhere(matLabel(l10n, match.matNumber), match.groupNumber),
          if (i.by != null) l10n.incidentBy(i.by!),
          if (i.gaveRivalPoint) l10n.incidentGavePoint,
        ].join(' · '),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});

  final RecordMatch match;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final m = match;
    final started = m.status != MatchStatus.pending;
    final result = m.status != MatchStatus.finished
        ? null
        : m.points > m.rivalPoints
        ? l10n.recordWon
        : m.points < m.rivalPoints
        ? l10n.recordLost
        : l10n.recordDraw;
    final notes = [
      if (m.team != null) l10n.teamName(m.team!),
      if (m.asGhost) l10n.recordAsGhost,
      if (m.warnings > 0) l10n.recordWarnings(m.warnings),
      if (m.oneHandWarnings > 0) l10n.recordOneHand(m.oneHandWarnings),
      if (m.disqualified) l10n.recordDisqualified,
      if (m.rivalDisqualified) l10n.recordRivalDisqualified,
    ];
    return Card(
      child: ListTile(
        onTap: () => context.push('/club/matches/${m.matchId}'),
        leading: Icon(
          Icons.circle,
          size: 14,
          color: m.red ? CompetitorColor.red.color : CompetitorColor.blue.color,
          semanticLabel: m.red ? l10n.cornerRed : l10n.cornerBlue,
        ),
        title: Text(l10n.recordVs(m.rival)),
        subtitle: Text(
          [
            l10n.recordWhere(matLabel(l10n, m.matNumber), m.groupNumber),
            switch (m.status) {
              MatchStatus.pending => l10n.matchNotStarted,
              MatchStatus.inProgress => l10n.matchLive,
              MatchStatus.finished => result!,
            },
            ...notes,
          ].join(' · '),
        ),
        trailing: started
            ? Text(
                '${m.points} - ${m.rivalPoints}',
                style: text.titleLarge?.copyWith(
                  color: m.disqualified ? scheme.error : null,
                ),
              )
            : null,
      ),
    );
  }
}
