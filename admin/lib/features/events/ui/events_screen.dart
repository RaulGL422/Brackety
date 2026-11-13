import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/async_view.dart';
import '../../../core/page_header.dart';
import '../../../core/reason_dialog.dart';
import '../../../core/run_action.dart';
import '../../../core/table_line.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/events_api.dart';
import '../state/events_controller.dart';
import 'event_detail_view.dart';

const _columns = [4, 2, 3, 1, 1, 1, 2];

/// Every event, newest first; one opens its detail in the same tab.
class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedEventProvider);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: selected == null
          ? const _EventList()
          : EventDetailView(eventId: selected),
    );
  }
}

class _EventList extends ConsumerWidget {
  const _EventList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final events = ref.watch(eventsProvider);
    final refresh = ref.read(eventsProvider.notifier).refresh;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(title: l10n.eventsTitle, onRefresh: refresh),
        const _EventReset(),
        const SizedBox(height: AppSpacing.m),
        Expanded(
          child: AsyncView(
            value: events,
            onRetry: refresh,
            data: (page) => page.items.isEmpty
                ? Text(l10n.eventsEmpty, textAlign: TextAlign.center)
                : _EventPageView(page),
          ),
        ),
      ],
    );
  }
}

/// On the hall laptop: everything back to the package it started with.
class _EventReset extends ConsumerWidget {
  const _EventReset();

  static const _typed = 'REINICIAR';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final package = ref.watch(resetPackageProvider).value;
    if (package == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.restart_alt),
          label: Text(l10n.eventReset),
          onPressed: () => _reset(context, ref, package),
        ),
      ),
    );
  }

  Future<void> _reset(
    BuildContext context,
    WidgetRef ref,
    String package,
  ) async {
    final l10n = AppLocalizations.of(context);
    final reason = await askReason(
      context,
      title: l10n.eventResetTitle,
      body: l10n.eventResetBody(package, _typed),
      confirmLabel: l10n.eventReset,
      typeToConfirm: _typed,
    );
    if (reason == null || !context.mounted) return;
    await runAction(
      context,
      () => ref.read(eventsApiProvider).resetEvent(reason),
      done: (_) => l10n.eventResetDone,
      notFound: l10n.eventChanged,
    );
    ref.read(selectedEventProvider.notifier).close();
    ref.read(eventsProvider.notifier).refresh();
  }
}

class _EventPageView extends ConsumerWidget {
  const _EventPageView(this.page);

  final AdminEventPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final open = ref.read(selectedEventProvider.notifier).open;
    final go = ref.read(eventsPageProvider.notifier).go;
    return LayoutBuilder(
      builder: (context, constraints) {
        final table = constraints.maxWidth >= tableMinWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (table) ...[
              TableHeader(
                flexes: _columns,
                labels: [
                  l10n.eventColumnName,
                  l10n.eventColumnDate,
                  l10n.eventColumnOwner,
                  l10n.eventColumnMats,
                  l10n.eventColumnEntries,
                  l10n.eventColumnGroups,
                  l10n.eventColumnMatches,
                ],
              ),
              const Divider(height: 1),
            ],
            Expanded(
              child: ListView.separated(
                itemCount: page.items.length,
                separatorBuilder: (_, _) => table
                    ? const Divider(height: 1)
                    : const SizedBox(height: AppSpacing.s),
                itemBuilder: (context, i) {
                  final event = page.items[i];
                  return table
                      ? _EventLine(event: event, onOpen: () => open(event.id))
                      : _EventCard(event: event, onOpen: () => open(event.id));
                },
              ),
            ),
            if (page.pageCount > 1)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.m),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: AppSpacing.m,
                  children: [
                    OutlinedButton(
                      onPressed: page.page > 0 ? () => go(page.page - 1) : null,
                      child: Text(l10n.eventsPrevious),
                    ),
                    Text(l10n.eventsPageOf(page.page + 1, page.pageCount)),
                    OutlinedButton(
                      onPressed: page.hasNext ? () => go(page.page + 1) : null,
                      child: Text(l10n.eventsNext),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EventLine extends StatelessWidget {
  const _EventLine({required this.event, required this.onOpen});

  final AdminEventRow event;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: onOpen,
      child: TableLine(
        flexes: _columns,
        cells: [
          OneLineText(
            event.name,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(l10n.eventDate(event.date)),
          OneLineText(event.ownerEmail),
          Text('${event.mats}'),
          Text('${event.entries}'),
          Text('${event.groups}'),
          Text(l10n.eventMatchesProgress(event.matchesFinished, event.matches)),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onOpen});

  final AdminEventRow event;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: [
              Text(event.name, style: text.titleMedium),
              Text(l10n.eventDate(event.date)),
              Text(event.ownerEmail, style: text.bodySmall),
              Text(
                l10n.eventCounts(
                  event.entries,
                  event.groups,
                  event.matchesFinished,
                  event.matches,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
