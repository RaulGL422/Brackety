import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/async_view.dart';
import '../../../core/group_colors.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../events/state/events_providers.dart';
import '../data/grouping_models.dart';
import '../data/grouping_repository.dart';
import '../state/group_draft.dart';
import '../state/grouping_providers.dart';
import 'draft_panel.dart';

/// A category's participants: pick 4 (or 3 and a ghost) per group and send them to a mat.
class GroupBuilderScreen extends ConsumerStatefulWidget {
  const GroupBuilderScreen({
    super.key,
    required this.eventId,
    required this.categoryId,
    this.categoryName,
  });

  final String eventId;
  final String categoryId;
  final String? categoryName;

  @override
  ConsumerState<GroupBuilderScreen> createState() => _GroupBuilderScreenState();
}

class _GroupBuilderScreenState extends ConsumerState<GroupBuilderScreen> {
  GroupDraft? _draft;
  var _sort = ParticipantSort.name;
  var _busy = false;

  CategoryKey get _key =>
      (eventId: widget.eventId, categoryId: widget.categoryId);

  Future<void> _create(GroupDraft draft) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final created = await ref
          .read(groupingRepositoryProvider)
          .create(widget.eventId, widget.categoryId, draft.groups);
      setState(() => _draft = GroupDraft(maxGroups: draft.maxGroups));
      _refresh();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.groupsCreatedTitle(created.groupNumbers.length)),
          content: Text(
            l10n.groupsCreatedBody(
              created.groupNumbers.map(l10n.draftGroup).join(', '),
              created.matNumber,
            ),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
    } on DioException catch (e) {
      final conflict = e.response?.statusCode == 409;
      if (conflict) _refresh();
      messenger.showSnackBar(
        SnackBar(
          content: Text(conflict ? l10n.groupsConflict : l10n.groupsError),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _change(GroupDraft Function(GroupDraft) change, int maxGroups) =>
      setState(
        () => _draft = change(_draft ?? GroupDraft(maxGroups: maxGroups)),
      );

  void _refresh() {
    ref.invalidate(categoryParticipantsProvider(_key));
    ref.invalidate(categoriesProvider(widget.eventId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final maxGroups =
        ref.watch(myEventProvider(widget.eventId)).value?.maxGroupsPerMat ?? 1;
    final draft = _draft ?? GroupDraft(maxGroups: maxGroups);
    final participants = ref.watch(categoryParticipantsProvider(_key));
    final panel = DraftPanel(
      draft: draft,
      busy: _busy,
      onChanged: (change) => _change(change, maxGroups),
      onCreate: () => _create(draft),
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
              draft: draft,
              onTap: () => _change(
                (d) => d.toggle(sorted[i].id, grouped: sorted[i].isGrouped),
                maxGroups,
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
    required this.draft,
    required this.onTap,
  });

  final CategoryParticipant participant;
  final GroupDraft draft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = participant;
    final state = draft.stateOf(p.id, grouped: p.isGrouped);
    final draftIndex = draft.groupOf(p.id);
    final height = p.heightCm == null
        ? l10n.heightUnknown
        : l10n.heightCm(p.heightCm!);
    final details = l10n.participantDetails(p.age, height);
    return ListTile(
      enabled: state != PickState.unavailable,
      onTap: onTap,
      leading: _PickMark(state: state, draftIndex: draftIndex),
      title: Text(p.fullName),
      subtitle: Text(
        p.isGrouped
            ? '$details · ${l10n.participantGrouped(p.groupNumber!, p.matNumber!)}'
            : details,
      ),
      trailing: state == PickState.ghost
          ? Chip(label: Text(l10n.ghostBadge))
          : null,
    );
  }
}

/// Checkbox-like mark in the colour and number of the draft group the participant is in.
class _PickMark extends StatelessWidget {
  const _PickMark({required this.state, required this.draftIndex});

  final PickState state;
  final int? draftIndex;

  @override
  Widget build(BuildContext context) {
    if (draftIndex == null) {
      return Icon(
        state == PickState.unavailable
            ? Icons.block
            : Icons.check_box_outline_blank,
      );
    }
    final color = groupColor(draftIndex!);
    return CircleAvatar(
      backgroundColor: color.color,
      foregroundColor: color.onColor,
      child: state == PickState.ghost
          ? const Icon(Icons.visibility_off_outlined)
          : Text('${draftIndex! + 1}'),
    );
  }
}
