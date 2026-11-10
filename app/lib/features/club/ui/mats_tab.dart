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

/// In review: the warning container, its text readable in light and dark. The estimated end
/// only while the mat has something left to play.
class _MatCard extends StatelessWidget {
  const _MatCard({required this.mat});

  final MatOverview mat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final time = DateFormat.Hm(Localizations.localeOf(context).toLanguageTag());
    final scheme = Theme.of(context).colorScheme;
    final colors = BracketyColors.of(context);
    final inReview = mat.matchesInReview > 0;
    final busy = mat.matchInProgress || mat.pendingMatches > 0;
    final (background, foreground) = inReview
        ? (colors.warningContainer, colors.onWarningContainer)
        : mat.matchInProgress
        ? (scheme.secondaryContainer, scheme.onSecondaryContainer)
        : (null, scheme.onSurface);
    return Card(
      color: background,
      child: ListTile(
        textColor: foreground,
        iconColor: foreground,
        leading: Icon(
          inReview
              ? Icons.gavel
              : mat.matchInProgress
              ? Icons.sports_martial_arts
              : Icons.pause_circle_outline,
        ),
        title: Text(
          '${l10n.matTitle(mat.number)} · '
          '${mat.referee ?? l10n.matNoReferee}',
        ),
        subtitle: Text(
          [
            mat.matchInProgress ? l10n.matFighting : l10n.matIdle,
            l10n.matSummary(mat.groups, mat.pendingMatches),
            if (busy) l10n.matEstimatedEnd(time.format(mat.estimatedEnd)),
            if (inReview) l10n.matsInReview(mat.matchesInReview),
          ].join('\n'),
          style: TextStyle(color: foreground),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/club/mats/${mat.id}?number=${mat.number}'),
      ),
    );
  }
}
