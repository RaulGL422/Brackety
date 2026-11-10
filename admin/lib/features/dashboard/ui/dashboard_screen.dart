import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/async_view.dart';
import '../../../core/page_header.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/metrics_api.dart';
import '../state/metrics_controller.dart';

/// The platform at a glance: one tile per count, in sections. Colour only where something needs
/// a look (matches in review, server errors), always with an icon and words.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final metrics = ref.watch(metricsProvider);
    final refresh = ref.read(metricsProvider.notifier).refresh;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(title: l10n.dashboardTitle, onRefresh: refresh),
          Expanded(
            child: AsyncView(
              value: metrics,
              onRetry: refresh,
              data: (m) => _Sections(m),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sections extends StatelessWidget {
  const _Sections(this.m);

  final AdminMetrics m;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    int profile(String type) => m.byProfile[type] ?? 0;
    return ListView(
      children: [
        Text(l10n.metricsAt(m.at.toLocal())),
        _Section(
          title: l10n.metricsUsers,
          tiles: [
            _Tile(l10n.metricsActiveAccounts, m.activeAccounts),
            _Tile(l10n.metricsNewLast7Days, m.newLast7Days),
            _Tile(l10n.metricsUnverified, m.unverified),
            _Tile(l10n.metricsPendingDeletion, m.pendingDeletion),
            _Tile(l10n.metricsOrganizersPending, m.organizersPending),
            _Tile(l10n.metricsActiveSessions, m.activeSessions),
            _Tile(l10n.metricsActiveLocks, m.activeLocks),
          ],
        ),
        _Section(
          title: l10n.metricsProfiles,
          tiles: [
            _Tile(l10n.metricsClubs, profile('CLUB')),
            _Tile(l10n.metricsEntities, profile('EXTERNAL_ENTITY')),
            _Tile(l10n.metricsHelpers, profile('HELPER')),
            _Tile(l10n.metricsStudents, profile('STUDENT')),
            _Tile(l10n.metricsExternals, profile('EXTERNAL')),
          ],
        ),
        _Section(
          title: l10n.metricsEvents,
          tiles: [
            _Tile(l10n.metricsEventsTotal, m.events),
            _Tile(l10n.metricsUpcoming, m.upcomingEvents),
            _Tile(l10n.metricsEntries, m.entries),
            _Tile(l10n.metricsImports, m.importsLast7Days),
            _Tile(l10n.metricsImported, m.importedLast7Days),
          ],
        ),
        _Section(
          title: l10n.metricsActivity,
          tiles: [
            _Tile(l10n.metricsMatchesFinished, m.matchesFinished24h),
            _Tile(l10n.metricsScoreboardActions, m.scoreboardActions24h),
            _Tile(l10n.metricsGroupsCreated, m.groupsCreated24h),
            _Tile(l10n.metricsInProgress, m.matchesInProgress),
            _Tile(
              l10n.metricsInReview,
              m.matchesInReview,
              status: m.matchesInReview > 0
                  ? _Status.warning(l10n.metricsInReviewNote)
                  : null,
            ),
          ],
        ),
        _Section(
          title: l10n.metricsServer,
          tiles: [
            _Tile(
              l10n.metricsServerErrors,
              m.serverErrors,
              note: l10n.metricsSince(m.startedAt.toLocal()),
              status: m.serverErrors > 0
                  ? _Status.error(l10n.metricsServerErrorsNote)
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.tiles});

  final String title;
  final List<_Tile> tiles;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.s,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: tiles,
          ),
        ],
      ),
    );
  }
}

class _Status {
  const _Status.warning(this.text) : error = false;
  const _Status.error(this.text) : error = true;

  final String text;
  final bool error;
}

/// A count: its label, the number and, when there is one, a note or a state to look at.
class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value, {this.note, this.status});

  final String label;
  final int value;
  final String? note;
  final _Status? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = BracketyColors.of(context);
    final (fill, onFill) = switch (status) {
      _Status(error: true) => (scheme.errorContainer, scheme.onErrorContainer),
      _Status() => (colors.warningContainer, colors.onWarningContainer),
      null => (scheme.surfaceContainerLow, scheme.onSurface),
    };
    return SizedBox(
      width: 184,
      child: Card(
        color: fill,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: status == null ? scheme.onSurfaceVariant : onFill,
                ),
              ),
              Text(
                '$value',
                style: theme.textTheme.headlineMedium?.copyWith(color: onFill),
              ),
              if (note case final note?)
                Text(
                  note,
                  style: theme.textTheme.bodySmall?.copyWith(color: onFill),
                ),
              if (status case final status?)
                Row(
                  spacing: AppSpacing.xs,
                  children: [
                    Icon(
                      status.error ? Icons.error_outline : Icons.warning_amber,
                      size: 18,
                      color: onFill,
                    ),
                    Expanded(
                      child: Text(
                        status.text,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onFill,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
