import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_bar_action.dart';
import '../../../core/async_view.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/ui/widgets/confirm_dialog.dart';
import '../data/grouping_models.dart';
import '../data/grouping_repository.dart';
import '../state/group_draft.dart';
import '../state/grouping_providers.dart';
import 'create_groups.dart';
import 'draft_panel.dart';
import 'pick_mark.dart';
import '../../../core/up_button.dart';

/// A team category (docs/modulos/prototipo-f1-equipos.md): make teams from its participants, then
/// group 4 teams (or 3 and a ghost team) and send them to a mat. "Individual group" opens the usual
/// screen for those left without a team.
class TeamCategoryScreen extends ConsumerWidget {
  const TeamCategoryScreen({
    super.key,
    required this.eventId,
    required this.categoryId,
    required this.categoryName,
    required this.teamSize,
  });

  final String eventId;
  final String categoryId;
  final String categoryName;
  final int teamSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final key = (eventId: eventId, categoryId: categoryId);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: UpButton(
            label: l10n.categoriesTitle,
            fallback: '/events/$eventId/categories',
          ),
          leadingWidth: UpButton.leadingWidth(context),
          title: Text(l10n.categoryAges(categoryName)),
          actions: [
            AppBarAction(
              icon: Icons.person_outline,
              label: l10n.individualGroup,
              // Replaces this screen, so back goes to the categories, not here.
              onPressed: () => context.pushReplacement(
                '/events/$eventId/categories/$categoryId?teamSize=$teamSize',
                extra: categoryName,
              ),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.tabParticipants),
              Tab(text: l10n.tabTeams),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TeamMaker(categoryKey: key, teamSize: teamSize),
            _TeamGroups(categoryKey: key, teamSize: teamSize),
          ],
        ),
      ),
    );
  }
}

void _refresh(WidgetRef ref, CategoryKey key) {
  ref.invalidate(categoryParticipantsProvider(key));
  ref.invalidate(categoryTeamsProvider(key));
  ref.invalidate(categoriesProvider(key.eventId));
}

/// Pick [teamSize] participants and make "Equipo N" with them. Someone who already has a team or a
/// group joins as a ghost: fights for the team but does not score for it.
class _TeamMaker extends ConsumerStatefulWidget {
  const _TeamMaker({required this.categoryKey, required this.teamSize});

  final CategoryKey categoryKey;
  final int teamSize;

  @override
  ConsumerState<_TeamMaker> createState() => _TeamMakerState();
}

class _TeamMakerState extends ConsumerState<_TeamMaker> {
  var _picks = <String>[];
  var _sort = ParticipantSort.name;
  var _busy = false;

  void _toggle(String id) => setState(() {
    if (_picks.contains(id)) {
      _picks = [..._picks]..remove(id);
    } else if (_picks.length < widget.teamSize) {
      _picks = [..._picks, id];
    }
  });

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    final key = widget.categoryKey;
    setState(() => _busy = true);
    try {
      final team = await ref
          .read(groupingRepositoryProvider)
          .createTeam(
            key.eventId,
            key.categoryId,
            _picks,
            ghostIds: [..._ghosts],
          );
      _picks = [];
      toasts.show(l10n.teamCreated(l10n.teamName(team.number)));
      _refresh(ref, key);
    } on DioException catch (e) {
      final conflict = e.response?.statusCode == 409;
      if (conflict) _refresh(ref, key);
      toasts.show(
        conflict ? l10n.teamConflict : l10n.teamError,
        kind: ToastKind.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The picks who already compete elsewhere: they join as ghosts.
  Set<String> get _ghosts {
    final all =
        ref.read(categoryParticipantsProvider(widget.categoryKey)).value ??
        const <CategoryParticipant>[];
    return {
      for (final p in all)
        if (p.isTaken && _picks.contains(p.id)) p.id,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final participants = ref.watch(
      categoryParticipantsProvider(widget.categoryKey),
    );
    final ghosts = _ghosts;
    final complete = _picks.length == widget.teamSize;
    final list = AsyncView(
      value: participants,
      onRetry: () => _refresh(ref, widget.categoryKey),
      data: (all) {
        final sorted = sortParticipants(all, _sort);
        return ListView.builder(
          itemCount: sorted.length + 1,
          itemBuilder: (context, i) => i == 0
              ? _SortBar(
                  sort: _sort,
                  onChanged: (s) => setState(() => _sort = s),
                )
              : _PersonTile(
                  participant: sorted[i - 1],
                  picked: _picks.contains(sorted[i - 1].id),
                  ghost: ghosts.contains(sorted[i - 1].id),
                  enabled:
                      _picks.contains(sorted[i - 1].id) ||
                      _picks.length < widget.teamSize,
                  onTap: () => _toggle(sorted[i - 1].id),
                ),
        );
      },
    );
    final panel = Material(
      elevation: 3,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.newTeamCount(_picks.length, widget.teamSize),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (ghosts.isNotEmpty)
                Text(
                  l10n.teamGhostHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: AppSpacing.s),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSizes.touchTarget),
                ),
                onPressed: complete && !_busy ? _create : null,
                child: Text(l10n.createTeam),
              ),
            ],
          ),
        ),
      ),
    );
    return _ListWithPanel(list: list, panel: panel);
  }
}

/// Pick 4 teams (or 3 and a ghost team) per group and send them to a mat.
class _TeamGroups extends ConsumerStatefulWidget {
  const _TeamGroups({required this.categoryKey, required this.teamSize});

  final CategoryKey categoryKey;
  final int teamSize;

  @override
  ConsumerState<_TeamGroups> createState() => _TeamGroupsState();
}

class _TeamGroupsState extends ConsumerState<_TeamGroups> {
  late var _group = _fresh();
  String? _matId;
  var _busy = false;

  DraftGroup _fresh() => DraftGroup(ghostTeamSize: widget.teamSize);

  void _change(DraftGroup Function(DraftGroup) change) =>
      setState(() => _group = change(_group));

  Future<void> _create() async {
    if (!await _acceptOverlaps()) return;
    if (!mounted) return;
    setState(() => _busy = true);
    final created = await createGroup(
      context,
      ref,
      eventId: widget.categoryKey.eventId,
      categoryId: widget.categoryKey.categoryId,
      group: _group,
      matId: _matId,
      refresh: () => _refresh(ref, widget.categoryKey),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (created) {
        _group = _fresh();
        _matId = null;
      }
    });
  }

  /// A participant in two teams of the group (a ghost member, say) would fight their own team: the
  /// helper may still go on.
  Future<bool> _acceptOverlaps() async {
    final l10n = AppLocalizations.of(context);
    final teams =
        ref.read(categoryTeamsProvider(widget.categoryKey)).value ??
        const <Team>[];
    final chosen = [
      for (final t in teams)
        if (_group.members.contains(t.id)) t,
    ];
    final overlaps = overlappingMembers(chosen);
    if (overlaps.isEmpty) return true;
    final names = {
      for (final t in chosen)
        for (final m in t.members) m.participantId: m.fullName,
    };
    final lines = [
      for (final MapEntry(:key, :value) in overlaps.entries)
        l10n.teamOverlapLine(names[key]!, value.map(l10n.teamName).join(', ')),
    ];
    return confirmAction(
      context,
      title: l10n.teamOverlapTitle,
      body: l10n.teamOverlapBody(lines.join('\n')),
      confirmLabel: l10n.createAnyway,
    );
  }

  Future<void> _pickGhostTeam(List<Team> teams) async {
    final group = _group;
    final own = {
      for (final t in teams)
        if (group.members.contains(t.id))
          for (final m in t.members) m.participantId,
    };
    final picked = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _GhostTeamSheet(
        categoryKey: widget.categoryKey,
        size: widget.teamSize,
        initial: group.ghostTeam,
        excluded: own,
      ),
    );
    if (picked != null) _change((g) => g.setGhostTeam(picked));
  }

  Future<void> _delete(Team team) async {
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    final name = l10n.teamName(team.number);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        actionsOverflowDirection: VerticalDirection.up,
        actionsOverflowButtonSpacing: 8,
        title: Text(l10n.deleteTeam),
        content: Text(l10n.deleteTeamConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteTeam),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(groupingRepositoryProvider)
          .deleteTeam(widget.categoryKey.eventId, team.id);
    } on DioException {
      toasts.show(l10n.deleteTeamError, kind: ToastKind.error);
    }
    if (_group.contains(team.id)) setState(() => _group = _fresh());
    _refresh(ref, widget.categoryKey);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final key = widget.categoryKey;
    // As with participants: a team another helper grouped (or deleted) leaves the draft at once.
    ref.listen(categoryTeamsProvider(key), (_, next) {
      final all = next.value;
      if (_busy || all == null) return;
      final present = {for (final t in all) t.id: t};
      final gone = {
        for (final id in _group.members)
          if (present[id] == null || present[id]!.groupNumber != null)
            id: present[id] == null ? '' : l10n.teamName(present[id]!.number),
      };
      if (gone.isEmpty) return;
      setState(() => _group = _group.without(gone.keys.toSet()));
      final names = gone.values.where((n) => n.isNotEmpty);
      if (names.isNotEmpty) {
        Toasts.of(context)
            .show(l10n.draftTakenElsewhere(names.length, names.join(', ')));
      }
    });
    final teams = ref.watch(categoryTeamsProvider(key));
    final list = AsyncView(
      value: teams,
      onRetry: () => _refresh(ref, key),
      data: (all) => all.isEmpty
          ? Center(child: Text(l10n.teamsEmpty))
          : ListView.builder(
              itemCount: all.length,
              itemBuilder: (context, i) => _TeamTile(
                team: all[i],
                group: _group,
                onTap: () => _change(
                  (g) => g.toggle(all[i].id, grouped: all[i].isGrouped),
                ),
                onDelete: all[i].isGrouped ? null : () => _delete(all[i]),
                onUndoGroup: all[i].canUndoGroup
                    ? () => undoGroup(
                        context,
                        ref,
                        eventId: key.eventId,
                        groupId: all[i].groupId!,
                        number: all[i].groupNumber!,
                        refresh: () => _refresh(ref, key),
                      )
                    : null,
              ),
            ),
    );
    final panel = DraftPanel(
      eventId: key.eventId,
      group: _group,
      matId: _matId,
      busy: _busy,
      onChanged: _change,
      onMatChanged: (id) => setState(() => _matId = id),
      onCreate: _create,
      labelOf: (id) {
        final team = teams.value?.where((t) => t.id == id).firstOrNull;
        return team == null ? '' : l10n.teamName(team.number);
      },
      onPickGhostTeam: () => _pickGhostTeam(teams.value ?? const []),
    );
    return _ListWithPanel(list: list, panel: panel);
  }
}

class _TeamTile extends StatelessWidget {
  const _TeamTile({
    required this.team,
    required this.group,
    required this.onTap,
    required this.onDelete,
    this.onUndoGroup,
  });

  final Team team;
  final DraftGroup group;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onUndoGroup;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = group.stateOf(team.id, grouped: team.isGrouped);
    final names = team.members
        .map((m) => m.ghost ? l10n.ghostMemberName(m.fullName) : m.fullName)
        .join(', ');
    return ListTile(
      enabled: state != PickState.unavailable,
      onTap: onTap,
      leading: PickMark(state: state, onTap: onTap),
      title: Text(l10n.teamName(team.number)),
      subtitle: Text(
        team.isGrouped
            ? '$names\n${l10n.participantGrouped(team.groupNumber!, team.matNumber!)}'
            : names,
      ),
      isThreeLine: team.isGrouped,
      trailing: onDelete != null
          ? IconButton(
              tooltip: l10n.deleteTeam,
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            )
          : onUndoGroup != null
          ? IconButton(
              tooltip: l10n.undoGroupNumber(team.groupNumber!),
              icon: const Icon(Icons.undo),
              onPressed: onUndoGroup,
            )
          : null,
    );
  }
}

/// Any [size] participants of the category, except those of the group's own teams.
class _GhostTeamSheet extends ConsumerStatefulWidget {
  const _GhostTeamSheet({
    required this.categoryKey,
    required this.size,
    required this.initial,
    required this.excluded,
  });

  final CategoryKey categoryKey;
  final int size;
  final List<String> initial;
  final Set<String> excluded;

  @override
  ConsumerState<_GhostTeamSheet> createState() => _GhostTeamSheetState();
}

class _GhostTeamSheetState extends ConsumerState<_GhostTeamSheet> {
  late var _picks = [...widget.initial];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final participants = ref.watch(
      categoryParticipantsProvider(widget.categoryKey),
    );
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: Text(
              l10n.draftGhostTeamHint(widget.size),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: AsyncView(
              value: participants,
              onRetry: () => ref.invalidate(
                categoryParticipantsProvider(widget.categoryKey),
              ),
              data: (all) {
                final options = [
                  for (final p in all)
                    if (!widget.excluded.contains(p.id)) p,
                ];
                return ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, i) {
                    final p = options[i];
                    final picked = _picks.contains(p.id);
                    return CheckboxListTile(
                      value: picked,
                      title: Text(p.fullName),
                      subtitle: p.teamNumber == null
                          ? null
                          : Text(l10n.teamName(p.teamNumber!)),
                      onChanged: picked || _picks.length < widget.size
                          ? (_) => setState(
                              () => _picks = picked
                                  ? ([..._picks]..remove(p.id))
                                  : [..._picks, p.id],
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSizes.touchTarget),
                ),
                onPressed: _picks.length == widget.size
                    ? () => Navigator.of(context).pop(_picks)
                    : null,
                child: Text(l10n.pickGhostTeam(_picks.length, widget.size)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.participant,
    required this.picked,
    required this.enabled,
    required this.onTap,
    this.ghost = false,
  });

  final CategoryParticipant participant;
  final bool picked;
  final bool enabled;
  final VoidCallback onTap;

  /// Picked while competing elsewhere: joins the team as a ghost.
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = participant;
    final height = p.heightCm == null
        ? l10n.heightUnknown
        : l10n.heightCm(p.heightCm!);
    return ListTile(
      enabled: enabled,
      onTap: onTap,
      leading: Checkbox(
        value: picked,
        onChanged: enabled ? (_) => onTap() : null,
      ),
      title: Text(p.fullName),
      subtitle: Text(
        [
          l10n.participantDetails(p.age, height),
          if (p.teamNumber != null) l10n.teamName(p.teamNumber!),
          if (p.isGrouped)
            l10n.participantGrouped(p.groupNumber!, p.matNumber!),
          if (p.isGrouped && p.groupCreatedBy != null)
            l10n.groupCreatedBy(p.groupCreatedBy!),
          if (ghost) l10n.teamGhostMember,
        ].join(' · '),
      ),
      trailing: ghost ? const Icon(Icons.blur_on) : null,
    );
  }
}

class _SortBar extends StatelessWidget {
  const _SortBar({required this.sort, required this.onChanged});

  final ParticipantSort sort;
  final ValueChanged<ParticipantSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s),
      child: Center(
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
          selected: {sort},
          onSelectionChanged: (s) => onChanged(s.single),
        ),
      ),
    );
  }
}

/// List and panel side by side on wide screens, panel under the list otherwise.
class _ListWithPanel extends StatelessWidget {
  const _ListWithPanel({required this.list, required this.panel});

  final Widget list;
  final Widget panel;

  @override
  Widget build(BuildContext context) {
    if (WindowSize.of(context) == WindowSize.expanded) {
      return Row(
        children: [
          Expanded(flex: 3, child: list),
          Expanded(
            flex: 2,
            child: Align(alignment: Alignment.topCenter, child: panel),
          ),
        ],
      );
    }
    return Column(
      children: [
        Expanded(child: list),
        panel,
      ],
    );
  }
}
