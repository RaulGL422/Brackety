import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/async_view.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../offline/ui/confirm_sign_out.dart';
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
        actions: const [
          _AccountMenu(),
          SizedBox(width: AppSpacing.s),
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
                  FilledButton.icon(
                    icon: const Icon(Icons.sports_martial_arts),
                    label: Text(l10n.eventMyMat(event.matNumber!)),
                    onPressed: () => context.push(
                      '/mats/${event.matId}?number=${event.matNumber}',
                    ),
                  ),
                if (event.roles.contains(EventRole.club))
                  FilledButton.icon(
                    icon: const Icon(Icons.dashboard_outlined),
                    label: Text(l10n.eventClubPanel),
                    onPressed: () => context.push('/events/${event.id}/club'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _AccountItem { settings, connection, signOut }

/// One labelled button instead of three bare icons: people did not know what each one did.
class _AccountMenu extends ConsumerWidget {
  const _AccountMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final error = Theme.of(context).colorScheme.error;
    return PopupMenuButton<_AccountItem>(
      tooltip: l10n.accountMenu,
      onSelected: (item) => switch (item) {
        _AccountItem.settings => context.push('/settings'),
        _AccountItem.connection => context.push('/connection'),
        _AccountItem.signOut => confirmSignOut(context, ref),
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _AccountItem.settings,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.settings_outlined),
            title: Text(l10n.settingsTitle),
          ),
        ),
        PopupMenuItem(
          value: _AccountItem.connection,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.dns_outlined),
            title: Text(l10n.navConnection),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _AccountItem.signOut,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            iconColor: error,
            textColor: error,
            leading: const Icon(Icons.logout),
            title: Text(l10n.logout),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_circle_outlined),
            const SizedBox(width: AppSpacing.xs),
            Text(
              l10n.accountMenu,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
