import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/async_view.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/grouping_models.dart';
import '../data/grouping_repository.dart';
import '../state/group_draft.dart';
import '../state/grouping_providers.dart';
import 'create_groups.dart';
import 'draft_panel.dart';
import 'pick_mark.dart';

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
          title: Text(l10n.categoryAges(categoryName)),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.person_outline),
              label: Text(l10n.individualGroup),
              onPressed: () => context.push(
                '/events/$eventId/categories/$categoryId?fromTeams=1',
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

/// Pick [teamSize] free participants and make "Equipo N" with them.
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
    final messenger = ScaffoldMessenger.of(context);
    final key = widget.categoryKey;
    setState(() => _busy = true);
    try {
      final team = await ref
          .read(groupingRepositoryProvider)
          .createTeam(key.eventId, key.categoryId, _picks);
      _picks = [];
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.teamCreated(l10n.teamName(team.number)))),
      );
      _refresh(ref, key);
    } on DioException catch (e) {
      final conflict = e.response?.statusCode == 409;
      if (conflict) _refresh(ref, key);
      messenger.showSnackBar(
        SnackBar(content: Text(conflict ? l10n.teamConflict : l10n.teamError)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final participants = ref.watch(
      categoryParticipantsProvider(widget.categoryKey),
    );
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
                  enabled:
                      !sorted[i - 1].isTaken &&
                      (_picks.contains(sorted[i - 1].id) ||
                          _picks.length < widget.teamSize),
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
              const SizedBox(height: AppSpacing.s),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSizes.touchTarget),
                ),
                onPressed: _picks.length == widget.teamSize && !_busy
                    ? _create
                    : null,
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
    final messenger = ScaffoldMessenger.of(context);
    final name = l10n.teamName(team.number);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
      messenger.showSnackBar(SnackBar(content: Text(l10n.deleteTeamError)));
    }
    if (_group.contains(team.id)) setState(() => _group = _fresh());
    _refresh(ref, widget.categoryKey);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final key = widget.categoryKey;
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
  });

  final Team team;
  final DraftGroup group;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = group.stateOf(team.id, grouped: team.isGrouped);
    final names = team.members.map((m) => m.fullName).join(', ');
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
      trailing: onDelete == null
          ? null
          : IconButton(
              tooltip: l10n.deleteTeam,
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
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
  });

  final CategoryParticipant participant;
  final bool picked;
  final bool enabled;
  final VoidCallback onTap;

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
        ].join(' · '),
      ),
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
