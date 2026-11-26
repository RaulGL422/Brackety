import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../auth/data/registration.dart';
import '../../auth/state/account_controller.dart';
import '../../events/data/my_event.dart';
import '../../events/state/events_providers.dart';
import '../../league/ui/new_event_dialog.dart';
import '../data/league_overview.dart';
import 'account_menu.dart';
import 'finished_list.dart';
import 'league_cards.dart';

/// «Mis eventos» (Raul, 2026-11-26): what is on now first, then what comes, then what is over.
/// Each league once, at its phase that matters now; what opens it depends on the account's role.
class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizer = ref.watch(_organizerProvider);
    final wide = WindowSize.of(context) == WindowSize.expanded;
    final events = ref.watch(myEventsProvider);
    final hasEvents = events.value?.isNotEmpty ?? false;
    return Scaffold(
      // On a phone the way to create stays at hand; on a desktop it sits in the header.
      floatingActionButton: organizer && !wide && hasEvents
          ? const _NewEventButton(floating: true)
          : null,
      body: SafeArea(
        child: AsyncView(
          value: events,
          onRetry: () => ref.invalidate(myEventsProvider),
          data: (events) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(showNewEvent: organizer && wide && hasEvents),
              ),
              if (events.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _Empty(organizer: organizer),
                )
              else
                SliverToBoxAdapter(child: _Sections(events: events)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Only clubs and other organizers create events; an account let in by QR helps in one.
final _organizerProvider = Provider.autoDispose<bool>((ref) {
  final account = ref.watch(accountProvider).value;
  return account != null &&
      !account.temporary &&
      account.profiles.any((p) => p.type.isOrganizer);
});

class _Header extends StatelessWidget {
  const _Header({required this.showNewEvent});

  final bool showNewEvent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Column(
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.l),
        // With large text the buttons go under the title instead of squeezing it; as wide as the
        // column, so the title stays left and the buttons right.
        child: SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.eventsTitle,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showNewEvent) ...[
                    const _NewEventButton(floating: false),
                    const SizedBox(width: AppSpacing.s),
                  ],
                  const Flexible(child: AccountMenu()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sections extends StatelessWidget {
  const _Sections({required this.events});

  final List<MyEvent> events;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sections = overviewOf(events);
    final wide = WindowSize.of(context) != WindowSize.compact;
    return _Column(
      child: Padding(
        // Room under the floating button on a phone.
        padding: const EdgeInsets.only(top: AppSpacing.l, bottom: 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (sections.live.isNotEmpty)
              _Section(
                title: l10n.homeLive,
                count: sections.live.length,
                children: [
                  for (final league in sections.live) LiveCard(league: league),
                ],
              ),
            if (sections.upcoming.isNotEmpty)
              _Section(
                title: l10n.homeUpcoming,
                count: sections.upcoming.length,
                columns: wide ? 2 : 1,
                children: [
                  for (final league in sections.upcoming)
                    UpcomingCard(league: league),
                ],
              ),
            if (sections.finished.isNotEmpty)
              _Section(
                title: l10n.homeFinished,
                count: sections.finished.length,
                children: [FinishedList(leagues: sections.finished)],
              ),
          ],
        ),
      ),
    );
  }
}

/// A section's title with how many events it holds, in a square like a group's number.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.count,
    required this.children,
    this.columns = 1,
  });

  final String title;
  final int count;
  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            label: '$title, ${l10n.homeCount(count)}',
            excludeSemantics: true,
            child: Row(
              children: [
                Flexible(
                  child: Text(title, style: theme.textTheme.headlineMedium),
                ),
                const SizedBox(width: AppSpacing.s),
                Container(
                  constraints: const BoxConstraints(minWidth: 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.onSurface,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.s),
                  ),
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          if (columns == 1)
            for (final (i, child) in children.indexed) ...[
              if (i > 0) const SizedBox(height: AppSpacing.m),
              child,
            ]
          else
            _Grid(columns: columns, children: children),
        ],
      ),
    );
  }
}

/// Cards side by side, two to a row.
class _Grid extends StatelessWidget {
  const _Grid({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < children.length; row += columns) ...[
          if (row > 0) const SizedBox(height: AppSpacing.m),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = row; i < row + columns; i++) ...[
                if (i > row) const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: i < children.length
                      ? children[i]
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.organizer});

  final bool organizer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _Column(
      maxWidth: AppSizes.formMaxWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.homeEmptyTitle, style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.s),
          Text(
            organizer ? l10n.homeEmptyOrganizer : l10n.homeEmptyHelper,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (organizer) ...[
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: Text(l10n.homeCreateFirst),
              onPressed: () => showNewEventDialog(context),
            ),
          ],
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

class _NewEventButton extends StatelessWidget {
  const _NewEventButton({required this.floating});

  final bool floating;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    if (!floating) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.onSurface,
          foregroundColor: scheme.surface,
        ),
        icon: const Icon(Icons.add),
        label: Text(l10n.newEventButton),
        onPressed: () => showNewEventDialog(context),
      );
    }
    return FloatingActionButton.extended(
      backgroundColor: scheme.onSurface,
      foregroundColor: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.l),
      ),
      icon: const Icon(Icons.add),
      label: Text(l10n.newEventButton),
      onPressed: () => showNewEventDialog(context),
    );
  }
}

/// The page's column: full width on a phone, centred and capped on wide windows.
class _Column extends StatelessWidget {
  const _Column({required this.child, this.maxWidth = 1200});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        child: child,
      ),
    ),
  );
}
