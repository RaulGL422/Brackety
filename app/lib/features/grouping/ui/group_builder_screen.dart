import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_bar_action.dart';
import '../../../core/async_view.dart';
import '../../../core/up_button.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../events/data/measure_rules.dart';
import '../../events/data/my_event.dart';
import '../../events/state/events_providers.dart';
import '../../mat/ui/mat_label.dart';
import '../data/grouping_models.dart';
import '../state/group_draft.dart';
import '../state/grouping_providers.dart';
import 'age_sections.dart';
import 'create_groups.dart';
import 'draft_panel.dart';
import 'measures.dart';
import 'pick_mark.dart';
import 'read_only_notice.dart';

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
  static const _splitByAge = Object();

  /// Only matters when the category mixes ages (F2-2).
  var _byAge = true;
  var _group = const DraftGroup();
  String? _matId;
  var _sort = ParticipantSort.name;
  var _busy = false;

  CategoryKey get _key =>
      (eventId: widget.eventId, categoryId: widget.categoryId);

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    final all =
        ref.read(categoryParticipantsProvider(_key)).value ??
        const <CategoryParticipant>[];
    final names = [
      for (final p in all)
        if (_group.contains(p.id)) p.fullName,
    ].join(', ');
    setState(() => _busy = true);
    final created = await createGroup(
      context,
      ref,
      eventId: widget.eventId,
      categoryId: widget.categoryId,
      group: _group,
      matId: _matId,
      refresh: _refresh,
      label: l10n.queuedGroupLabel(names),
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
    listenHelperQueue(context, ref);
    // Another helper (or the superadmin) changed the groups: whoever got a group meanwhile leaves the
    // draft now, not with a refusal on "Create". Not while this helper's own group is being sent.
    ref.listen(categoryParticipantsProvider(_key), (_, next) {
      if (_busy) return;
      final taken = {
        for (final p in next.value ?? const <CategoryParticipant>[])
          if (p.isTaken && _group.members.contains(p.id)) p.id: p.fullName,
      };
      if (taken.isEmpty) return;
      setState(() => _group = _group.without(taken.keys.toSet()));
      Toasts.of(
        context,
      ).show(l10n.draftTakenElsewhere(taken.length, taken.values.join(', ')));
    });
    final participants = ref.watch(categoryParticipantsProvider(_key));
    final can = ref.watch(myPermissionsProvider(widget.eventId));
    final groups = can.contains(EventPermission.groups);
    final measures = can.contains(EventPermission.measures);
    final panel = !groups
        ? null
        : DraftPanel(
            eventId: widget.eventId,
            group: _group,
            matId: _matId,
            busy: _busy,
            onChanged: (change) => setState(() => _group = change(_group)),
            onMatChanged: (id) => setState(() => _matId = id),
            onCreate: _create,
            labelOf: (id) {
              final all = participants.value ?? const <CategoryParticipant>[];
              final p = all.where((p) => p.id == id).firstOrNull;
              if (p == null) return '';
              final name = p.lastName.isEmpty
                  ? p.firstName
                  : '${p.firstName} ${p.lastName.characters.first}.';
              // Ages mixed in the category: the group shows whose age is whose (F2-2).
              return mixesAges(all) ? '$name · ${p.age}' : name;
            },
          );
    final list = AsyncView(
      value: participants,
      onRetry: _refresh,
      data: (all) {
        final rules = measureRulesOf(ref, widget.eventId);
        final sorted = sortParticipants(all, _sort);
        final mixed = mixesAges(all);
        final rows = <Object>[
          if (mixed) _splitByAge,
          ...(mixed && _byAge ? withAgeHeadings(sorted) : sorted),
        ];
        return RefreshIndicator(
          onRefresh: () =>
              ref.refresh(categoryParticipantsProvider(_key).future),
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final row = rows[i];
              if (row is AgeHeading) return AgeHeadingTile(heading: row);
              if (row is! CategoryParticipant) {
                return SplitByAgeChip(
                  selected: _byAge,
                  onSelected: (on) => setState(() => _byAge = on),
                );
              }
              final p = row;
              return _ParticipantTile(
                participant: p,
                group: _group,
                onUndoGroup: groups && p.canUndoGroup
                    ? () => undoGroup(
                        context,
                        ref,
                        eventId: widget.eventId,
                        groupId: p.groupId!,
                        number: p.groupNumber!,
                        refresh: _refresh,
                      )
                    : null,
                rules: rules,
                onTap: blockedByMeasures(rules, p)
                    ? !measures
                          ? null
                          : () async {
                              if (await showMeasuresDialog(
                                context,
                                widget.eventId,
                                p,
                              )) {
                                _refresh();
                              }
                            }
                    : !groups
                    ? null
                    : () => setState(
                        () => _group = _group.toggle(p.id, grouped: p.isTaken),
                      ),
              );
            },
          ),
        );
      },
    );
    final wide = WindowSize.of(context) == WindowSize.expanded;
    return Scaffold(
      appBar: AppBar(
        leading: UpButton(
          label: l10n.categoriesTitle,
          fallback: '/events/${widget.eventId}/categories',
        ),
        leadingWidth: UpButton.leadingWidth(context),
        title: Text(
          widget.categoryName == null
              ? l10n.categoriesTitle
              : l10n.categoryAges(widget.categoryName!),
        ),
        actions: [
          if (widget.teamSize != null)
            AppBarAction(
              icon: Icons.groups_outlined,
              label: l10n.teamGroup,
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
      body: Column(
        children: [
          if (!groups && !measures) const ReadOnlyNotice(),
          Expanded(
            child: wide && panel != null
                ? Row(
                    children: [
                      Expanded(flex: 3, child: list),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: panel,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(child: list),
                      ?panel,
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
    required this.participant,
    required this.group,
    required this.rules,
    required this.onTap,
    this.onUndoGroup,
  });

  final CategoryParticipant participant;
  final DraftGroup group;

  /// A required measure missing: tapping asks for it instead of picking.
  final MeasureRules rules;

  /// Null for whoever may not pick (nor measure, when blocked).
  final VoidCallback? onTap;
  final VoidCallback? onUndoGroup;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = participant;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final blocked = blockedByMeasures(rules, p);
    final state = group.stateOf(p.id, grouped: p.isTaken);
    return ListTile(
      enabled: blocked || state != PickState.unavailable,
      onTap: onTap,
      leading: blocked
          ? Icon(
              Icons.monitor_weight_outlined,
              color: Theme.of(context).colorScheme.error,
              semanticLabel: l10n.measuresWrite,
            )
          : onTap == null
          ? null
          : PickMark(state: state, onTap: onTap!),
      title: Text(p.fullName),
      subtitle: Text(
        [
          participantSummary(l10n, locale, rules, p),
          if (p.teamNumber != null) l10n.teamName(p.teamNumber!),
          if (p.isGrouped)
            l10n.participantGrouped(
              p.groupNumber!,
              matLabel(l10n, p.matNumber),
            ),
          if (p.isGrouped && p.groupCreatedBy != null)
            l10n.groupCreatedBy(p.groupCreatedBy!),
          if (p.queued) l10n.queuedPending,
        ].join(' · '),
      ),
      trailing: state == PickState.ghost
          ? Chip(label: Text(l10n.ghostBadge))
          : onUndoGroup == null
          ? null
          : IconButton(
              tooltip: l10n.undoGroupNumber(p.groupNumber!),
              icon: const Icon(Icons.undo),
              onPressed: onUndoGroup,
            ),
    );
  }
}
