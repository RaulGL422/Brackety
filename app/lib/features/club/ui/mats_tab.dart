import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/async_view.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/club_models.dart';
import '../state/club_providers.dart';

/// Every mat with its referee, load and estimated end; a tap opens its board.
class MatsTab extends ConsumerWidget {
  const MatsTab({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = matsOverviewProvider(eventId);
    return AsyncView(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      data: (mats) => mats.isEmpty
          ? Center(child: Text(l10n.matsEmpty))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.l),
              children: [for (final mat in mats) _MatCard(mat: mat)],
            ),
    );
  }
}

class _MatCard extends StatelessWidget {
  const _MatCard({required this.mat});

  final MatOverview mat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final time = DateFormat.Hm(Localizations.localeOf(context).toLanguageTag());
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: mat.matchInProgress ? scheme.primaryContainer : null,
      child: ListTile(
        leading: Icon(
          mat.matchInProgress
              ? Icons.sports_martial_arts
              : Icons.pause_circle_outline,
        ),
        title: Text(
          '${l10n.matTitle(mat.number)} · '
          '${mat.referee ?? l10n.matNoReferee}',
        ),
        subtitle: Text(
          '${mat.matchInProgress ? l10n.matFighting : l10n.matIdle}\n'
          '${l10n.matSummary(mat.groups, mat.pendingMatches)}',
        ),
        isThreeLine: true,
        trailing: Text(
          l10n.matEstimatedEnd(time.format(mat.estimatedEnd)),
          textAlign: TextAlign.end,
        ),
        onTap: () => context.push('/club/mats/${mat.id}'),
      ),
    );
  }
}
