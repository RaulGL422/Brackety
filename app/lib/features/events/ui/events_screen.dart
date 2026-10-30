import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/async_view.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../session/state/session_controller.dart';
import '../data/my_event.dart';
import '../state/events_providers.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.eventsTitle),
        actions: [
          IconButton(
            tooltip: l10n.navConnection,
            icon: const Icon(Icons.dns_outlined),
            onPressed: () => context.push('/connection'),
          ),
          IconButton(
            tooltip: l10n.logout,
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(sessionProvider.notifier).logout(),
          ),
        ],
      ),
      body: AsyncView(
        value: ref.watch(myEventsProvider),
        onRetry: () => ref.invalidate(myEventsProvider),
        data: (events) => events.isEmpty
            ? Center(child: Text(l10n.eventsEmpty))
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.l),
                itemCount: events.length,
                itemBuilder: (context, i) => _EventCard(event: events[i]),
              ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final MyEvent event;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.name, style: text.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(DateFormat.yMMMMd(locale).format(event.date)),
            const SizedBox(height: AppSpacing.m),
            Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              children: [
                if (event.roles.contains(EventRole.grouper))
                  FilledButton.icon(
                    icon: const Icon(Icons.group_add_outlined),
                    label: Text(l10n.eventMakeGroups),
                    onPressed: () =>
                        context.push('/events/${event.id}/categories'),
                  ),
                if (event.roles.contains(EventRole.referee) &&
                    event.matNumber != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.sports_martial_arts),
                    label: Text(
                      '${l10n.eventMyMat(event.matNumber!)} · ${l10n.comingSoon}',
                    ),
                    onPressed: null,
                  ),
                if (event.roles.contains(EventRole.club))
                  OutlinedButton.icon(
                    icon: const Icon(Icons.dashboard_outlined),
                    label: Text('${l10n.eventClubPanel} · ${l10n.comingSoon}'),
                    onPressed: null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
