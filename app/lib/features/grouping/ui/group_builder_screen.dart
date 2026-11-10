import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/async_view.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/grouping_models.dart';
import '../state/group_draft.dart';
import '../state/grouping_providers.dart';
import 'create_groups.dart';
import 'draft_panel.dart';
import 'pick_mark.dart';

/// A category's participants: pick 4 (or 3 and a ghost) and send them to a mat.
/// Opened from a team category ([teamSize] set) for those left without a team, with a way back.
class GroupBuilderScreen extends ConsumerStatefulWidget {
  const GroupBuilderScreen({
    super.key,
    required this.eventId,
    required this.categoryId,
    this.categoryName,
    this.teamSize,
  });

  final String eventId;
  final String categoryId;
  final String? categoryName;

  /// Set when opened from a team category.
  final int? teamSize;

  @override
  ConsumerState<GroupBuilderScreen> createState() => _GroupBuilderScreenState();
}

class _GroupBuilderScreenState extends ConsumerState<GroupBuilderScreen> {
  var _group = const DraftGroup();
  String? _matId;
  var _sort = ParticipantSort.name;
  var _busy = false;

  CategoryKey get _key =>
      (eventId: widget.eventId, categoryId: widget.categoryId);

  Future<void> _create() async {
    setState(() => _busy = true);
    final created = await createGroup(
      context,
      ref,
      eventId: widget.eventId,
      categoryId: widget.categoryId,
      group: _group,
      matId: _matId,
      refresh: _refresh,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (created) {
        _group = const DraftGroup();
        _matId = null;
      }
    });
  }

  void _refresh() {
    ref.invalidate(categoryParticipantsProvider(_key));
    ref.invalidate(categoriesProvider(widget.eventId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final participants = ref.watch(categoryParticipantsProvider(_key));
    final panel = DraftPanel(
      eventId: widget.eventId,
      group: _group,
      matId: _matId,
      busy: _busy,
      onChanged: (change) => setState(() => _group = change(_group)),
      onMatChanged: (id) => setState(() => _matId = id),
      onCreate: _create,
      labelOf: (id) {
        final p = participants.value?.where((p) => p.id == id).firstOrNull;
        if (p == null) return '';
        return p.lastName.isEmpty
            ? p.firstName
            : '${p.firstName} ${p.lastName.characters.first}.';
      },
    );
    final list = AsyncView(
      value: participants,
      onRetry: _refresh,
      data: (all) {
        final sorted = sortParticipants(all, _sort);
        return RefreshIndicator(
          onRefresh: () =>
              ref.refresh(categoryParticipantsProvider(_key).future),
          child: ListView.builder(
            itemCount: sorted.length,
            itemBuilder: (context, i) => _ParticipantTile(
              participant: sorted[i],
              group: _group,
              onTap: () => setState(
                () => _group = _group.toggle(
                  sorted[i].id,
                  grouped: sorted[i].isTaken,
                ),
              ),
            ),
          ),
        );
      },
    );
    final wide = WindowSize.of(context) == WindowSize.expanded;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryName == null
              ? l10n.categoriesTitle
              : l10n.categoryAges(widget.categoryName!),
        ),
        actions: [
          if (widget.teamSize != null)
            TextButton.icon(
              icon: const Icon(Icons.groups_outlined),
              label: Text(l10n.teamGroup),
              // Replaces this screen, so back goes to the categories.
              onPressed: () => context.pushReplacement(
                Uri(
                  path:
                      '/events/${widget.eventId}/categories/${widget.categoryId}/teams',
                  queryParameters: {
                    'name': widget.categoryName ?? '',
                    'size': '${widget.teamSize}',
                  },
                ).toString(),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(
            AppSizes.touchTarget + AppSpacing.m,
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s),
            child: SegmentedButton<ParticipantSort>(
              segments: [
                ButtonSegment(
                  value: ParticipantSort.name,
                  icon: const Icon(Icons.sort_by_alpha),
                  label: Text(l10n.sortByName),
                ),
                ButtonSegment(
                  value: ParticipantSort.height,
                  icon: const Icon(Icons.height),
                  label: Text(l10n.sortByHeight),
                ),
              ],
              selected: {_sort},
              onSelectionChanged: (s) => setState(() => _sort = s.single),
            ),
          ),
        ),
      ),
      body: wide
          ? Row(
              children: [
                Expanded(flex: 3, child: list),
                Expanded(
                  flex: 2,
                  child: Align(alignment: Alignment.topCenter, child: panel),
                ),
              ],
            )
          : Column(
              children: [
                Expanded(child: list),
                panel,
              ],
            ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
    required this.participant,
    required this.group,
    required this.onTap,
  });

  final CategoryParticipant participant;
  final DraftGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = participant;
    final state = group.stateOf(p.id, grouped: p.isTaken);
    final height = p.heightCm == null
        ? l10n.heightUnknown
        : l10n.heightCm(p.heightCm!);
    final details = l10n.participantDetails(p.age, height);
    return ListTile(
      enabled: state != PickState.unavailable,
      onTap: onTap,
      leading: PickMark(state: state, onTap: onTap),
      title: Text(p.fullName),
      subtitle: Text(
        [
          details,
          if (p.teamNumber != null) l10n.teamName(p.teamNumber!),
          if (p.isGrouped)
            l10n.participantGrouped(p.groupNumber!, p.matNumber!),
        ].join(' · '),
      ),
      trailing: state == PickState.ghost
          ? Chip(label: Text(l10n.ghostBadge))
          : null,
    );
  }
}
