import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../control/control_ui.dart';
import '../../events/data/my_event.dart';
import '../../events/state/events_providers.dart';
import '../../mat/state/mat_providers.dart';
import '../data/mat_overview.dart';
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
              children: [
                // GR-4: who is in each group, and moving them by dragging.
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, AppSizes.touchTarget),
                    ),
                    icon: const Icon(Icons.view_column_outlined),
                    label: Text(l10n.matGroupsTitle),
                    onPressed: () =>
                        context.push('/events/$eventId/mat-groups'),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                for (final mat in mats) _MatCard(eventId: eventId, mat: mat),
              ],
            ),
    );
  }
}

/// In review: the warning container, its text readable in light and dark. The estimated end
/// only while the mat has something left to play. Out of use: dimmed, since when and with whom,
/// and "Enable"; in use with a referee: "Disable" in sight (F1-1: hidden on the board, nobody found it).
class _MatCard extends ConsumerWidget {
  const _MatCard({required this.eventId, required this.mat});

  final String eventId;
  final MatOverview mat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (mat.isDisabled) return _DisabledMatCard(eventId: eventId, mat: mat);
    final controls = ref
        .watch(myPermissionsProvider(eventId))
        .contains(EventPermission.control);
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
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
            onTap: () =>
                context.push('/club/mats/${mat.id}?number=${mat.number}'),
          ),
          if (mat.referee != null && controls)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.l,
                0,
                AppSpacing.l,
                AppSpacing.s,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: foreground,
                    minimumSize: const Size(0, AppSizes.touchTarget),
                  ),
                  icon: const Icon(Icons.block),
                  label: Text(l10n.controlDisableMat),
                  onPressed: () async {
                    final board = await ref.read(
                      matBoardProvider(mat.id).future,
                    );
                    if (!context.mounted) return;
                    await disableMat(
                      context,
                      ref,
                      eventId: eventId,
                      matId: mat.id,
                      board: board,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DisabledMatCard extends ConsumerWidget {
  const _DisabledMatCard({required this.eventId, required this.mat});

  final String eventId;
  final MatOverview mat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final time = DateFormat.Hm(Localizations.localeOf(context).toLanguageTag());
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              textColor: scheme.onSurfaceVariant,
              iconColor: scheme.onSurfaceVariant,
              leading: const Icon(Icons.block),
              title: Text('${l10n.matTitle(mat.number)} · ${l10n.matDisabled}'),
              subtitle: Text(
                [
                  l10n.matDisabledSince(time.format(mat.disabledAt!)),
                  if (mat.disabledReferee case final referee?)
                    l10n.matDisabledReferee(referee),
                ].join('\n'),
              ),
            ),
            if (ref
                .watch(myPermissionsProvider(eventId))
                .contains(EventPermission.control))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, AppSizes.touchTarget),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.controlEnableMat),
                    onPressed: () =>
                        enableMat(context, ref, eventId: eventId, mat: mat),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
