import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/async_view.dart';
import '../../../core/medal.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../mat/data/mat_board.dart';
import '../data/club_models.dart';
import '../state/club_providers.dart';

/// A participant's day for the club: their place and points, and each match with the rival, the
/// score, the warnings and how it ended. A match opens its timeline.
Future<void> showParticipantRecord(
  BuildContext context, {
  required String eventId,
  required String participantId,
  required String name,
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
  });

  final String eventId;
  final String participantId;
  final String name;
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
            const SizedBox(height: AppSpacing.m),
            if (record.matches.isEmpty) Text(l10n.recordNoMatches),
            for (final m in record.matches) _MatchCard(match: m),
          ],
        );
      },
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
            l10n.recordWhere(m.matNumber, m.groupNumber),
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
