import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/async_view.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/club_models.dart';
import '../state/club_providers.dart';

enum StandingsOrder { points, name }

/// Live scores per student, filtered by category and sorted by points or name.
class StandingsTab extends ConsumerStatefulWidget {
  const StandingsTab({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<StandingsTab> createState() => _StandingsTabState();
}

class _StandingsTabState extends ConsumerState<StandingsTab> {
  String? _categoryId;
  var _order = StandingsOrder.points;

  @override
  Widget build(BuildContext context) {
    final provider = standingsProvider(widget.eventId);
    final categories =
        ref.watch(eventSettingsProvider(widget.eventId)).value?.categories ??
        const <EventCategory>[];
    return AsyncView(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      data: (standings) => _content(standings, categories),
    );
  }

  Widget _content(List<StandingRow> standings, List<EventCategory> categories) {
    final l10n = AppLocalizations.of(context);
    final rows = [
      for (final r in standings)
        if (_categoryId == null || r.categoryId == _categoryId) r,
    ];
    if (_order == StandingsOrder.name) {
      rows.sort(
        (a, b) => '${a.firstName} ${a.lastName}'.toLowerCase().compareTo(
          '${b.firstName} ${b.lastName}'.toLowerCase(),
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Wrap(
            spacing: AppSpacing.m,
            runSpacing: AppSpacing.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<String?>(
                value: _categoryId,
                items: [
                  DropdownMenuItem(child: Text(l10n.allCategories)),
                  for (final c in categories)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (id) => setState(() => _categoryId = id),
              ),
              SegmentedButton<StandingsOrder>(
                segments: [
                  ButtonSegment(
                    value: StandingsOrder.points,
                    label: Text(l10n.sortByPoints),
                  ),
                  ButtonSegment(
                    value: StandingsOrder.name,
                    label: Text(l10n.sortByName),
                  ),
                ],
                selected: {_order},
                onSelectionChanged: (s) => setState(() => _order = s.single),
              ),
            ],
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? Center(child: Text(l10n.standingsEmpty))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  itemCount: rows.length,
                  itemBuilder: (context, i) => _StandingTile(row: rows[i]),
                ),
        ),
      ],
    );
  }
}

class _StandingTile extends StatelessWidget {
  const _StandingTile({required this.row});

  final StandingRow row;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: CircleAvatar(child: Text('${row.position}')),
      title: Text('${row.firstName} ${row.lastName}'),
      subtitle: Text(
        '${l10n.participantAgeCategory(row.age, row.categoryName ?? l10n.noCategory)}\n'
        '${l10n.standingsDetail(row.attendancePoints, row.matchPoints, row.matches)}',
      ),
      isThreeLine: true,
      trailing: Text(
        l10n.standingsTotal(row.total),
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
