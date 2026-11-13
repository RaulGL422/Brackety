import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_bar_action.dart';
import '../../../core/async_view.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/grouping_models.dart';
import '../data/grouping_repository.dart';
import '../../auth/data/api_error.dart';
import '../state/group_draft.dart';
import '../state/helper_queue.dart';
import '../state/grouping_providers.dart';
import 'create_groups.dart';
import 'draft_panel.dart';
import 'pick_mark.dart';
import '../../../core/up_button.dart';
import '../../control/control_repository.dart';
import '../../control/control_ui.dart';
import '../../events/data/my_event.dart';
import '../../events/state/events_providers.dart';
import '../../mat/ui/mat_label.dart';

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
    listenHelperQueue(context, ref);
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

/// Pick 2 or 3 participants and make "Equipo N" with them. Someone who already has a team or a
/// group is locked; only after "Elegir comodines" can they join, as a wildcard: fights for the team
/// but does not score for it (Raul, 2026-11-13).
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

  /// Only with it on can someone who already competes be picked (as a wildcard).
  var _wildcards = false;

  void _toggle(CategoryParticipant p) => setState(() {
    if (_picks.contains(p.id)) {
      _picks = [..._picks]..remove(p.id);
    } else if (_picks.length < DraftGroup.maxTeam &&
        (_wildcards || !p.isTaken)) {
      _picks = [..._picks, p.id];
    }
  });

  void _setWildcards(bool on) => setState(() {
    _wildcards = on;
    // Off again: the wildcards picked leave the team.
    if (!on) _picks = [..._picks.where((id) => !_ghosts.contains(id))];
  });

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    final key = widget.categoryKey;
    setState(() => _busy = true);
    final ghosts = [..._ghosts];
    try {
      final team = await ref
          .read(groupingRepositoryProvider)
          .createTeam(key.eventId, key.categoryId, _picks, ghostIds: ghosts);
      _picks = [];
      toasts.show(l10n.teamCreated(l10n.teamName(team.number)));
      _refresh(ref, key);
    } on DioException catch (e) {
      // Without network it waits on the device and goes when the server answers again.
      if (ApiError.from(e).noResponse) {
        final label = l10n.queuedTeamLabel(_names(_picks));
        await ref
            .read(helperQueueProvider.notifier)
            .add(
              path: GroupingRepository.teamsPath(key.eventId, key.categoryId),
              body: {'participantIds': _picks, 'ghostIds': ghosts},
              label: label,
              people: [
                for (final id in _picks)
                  if (!ghosts.contains(id)) id,
              ],
            );
        _picks = [];
        toasts.show(l10n.queuedOffline(label));
        return;
      }
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

  String _names(List<String> ids) {
    final all =
        ref.read(categoryParticipantsProvider(widget.categoryKey)).value ??
        const <CategoryParticipant>[];
    return [
      for (final p in all)
        if (ids.contains(p.id)) p.fullName,
    ].join(', ');
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
    final complete = _picks.length >= DraftGroup.minTeam;
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
                      (_picks.length < DraftGroup.maxTeam &&
                          (_wildcards || !sorted[i - 1].isTaken)),
                  onTap: () => _toggle(sorted[i - 1]),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.newTeamCount(_picks.length, DraftGroup.maxTeam),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  FilterChip(
                    label: Text(l10n.teamPickWildcards),
                    selected: _wildcards,
                    onSelected: _setWildcards,
                  ),
                ],
              ),
              if (_wildcards || ghosts.isNotEmpty)
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

  DraftGroup _fresh() => const DraftGroup(ofTeams: true);

  void _change(DraftGroup Function(DraftGroup) change) =>
      setState(() => _group = change(_group));

  Future<void> _create() async {
    if (!_noOverlaps()) return;
    final l10n = AppLocalizations.of(context);
    final teams =
        ref.read(categoryTeamsProvider(widget.categoryKey)).value ??
        const <Team>[];
    final label = l10n.queuedGroupLabel(
      [
        for (final t in teams)
          if (_group.members.contains(t.id)) l10n.teamName(t.number),
      ].join(', '),
    );
    setState(() => _busy = true);
    final created = await createGroup(
      context,
      ref,
      eventId: widget.categoryKey.eventId,
      categoryId: widget.categoryKey.categoryId,
      group: _group,
      matId: _matId,
      refresh: () => _refresh(ref, widget.categoryKey),
      label: label,
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

  /// A participant in two teams of the group (a wildcard member, say) would fight their own team:
  /// never in one group (the server refuses it too).
  bool _noOverlaps() {
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
    Toasts.of(context).show(
      '${l10n.teamOverlapTitle}\n${lines.join('\n')}',
      kind: ToastKind.error,
    );
    return false;
  }

  Future<void> _pickGhostTeam(List<Team> teams) async {
    final group = _group;
    final own = {
      for (final t in teams)
        if (group.members.contains(t.id))
          for (final m in t.members) m.participantId,
      ...group.ghostTeamPeople,
    };
    final picked = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            _GhostTeamPage(categoryKey: widget.categoryKey, excluded: own),
      ),
    );
    if (picked != null) _change((g) => g.addGhostTeam(picked));
  }

  /// Everyone already in the draft: its real teams and its wildcard teams.
  Set<String> _draftPeople(List<Team> teams) => {
    for (final t in teams)
      if (_group.members.contains(t.id))
        for (final m in t.members) m.participantId,
    ..._group.ghostTeamPeople,
  };

  /// The index of the wildcard team made of exactly [team]'s people, or -1.
  int _asWildcard(Team team) {
    final people = {for (final m in team.members) m.participantId};
    return _group.ghostTeams.indexWhere(
      (g) => g.length == people.length && people.containsAll(g),
    );
  }

  /// A team already in another group joins this one as a wildcard team: tapped in wildcard mode.
  bool _canJoinAsWildcard(Team team, List<Team> teams) =>
      team.isTaken &&
      _group.canAddGhostTeam &&
      team.members.length >= DraftGroup.minTeam &&
      team.members.length <= DraftGroup.maxTeam &&
      team.members.every((m) => !_draftPeople(teams).contains(m.participantId));

  void _tapTeam(Team team, List<Team> teams) {
    final wildcard = _asWildcard(team);
    if (wildcard >= 0) {
      _change((g) => g.removeGhostTeam(wildcard));
    } else if (_canJoinAsWildcard(team, teams)) {
      _change(
        (g) => g.addGhostTeam([for (final m in team.members) m.participantId]),
      );
    } else {
      _change((g) => g.toggle(team.id, grouped: team.isTaken));
    }
  }

  /// "Equipo 7" for a whole team, or the people's names.
  String _ghostTeamLabel(List<String> people, List<Team> teams) {
    final l10n = AppLocalizations.of(context);
    for (final t in teams) {
      final ids = {for (final m in t.members) m.participantId};
      if (ids.length == people.length && ids.containsAll(people)) {
        return l10n.teamName(t.number);
      }
    }
    final names = {
      for (final p
          in ref.read(categoryParticipantsProvider(widget.categoryKey)).value ??
              const <CategoryParticipant>[])
        p.id: p.firstName,
    };
    return people.map((id) => names[id] ?? '').join(', ');
  }

  /// The club picks one of [team]'s people and the team they go to; the server checks the rest.
  Future<void> _moveMember(Team team, List<Team> all) async {
    final l10n = AppLocalizations.of(context);
    final member = await showDialog<TeamMember>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.controlMoveMemberWho),
        children: [
          for (final m in team.members)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, m),
              child: Text(m.fullName),
            ),
        ],
      ),
    );
    if (member == null || !mounted) return;
    final to = await showDialog<Team>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.controlMoveMemberTo),
        children: [
          for (final t in all)
            if (t.id != team.id)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, t),
                child: Text(
                  '${l10n.teamName(t.number)} · ${t.members.map((m) => m.fullName).join(', ')}',
                ),
              ),
        ],
      ),
    );
    if (to == null || !mounted) return;
    final key = widget.categoryKey;
    final moved = await runControl(
      context,
      () => ref
          .read(controlRepositoryProvider)
          .moveTeamMember(
            key.eventId,
            participantId: member.participantId,
            fromTeamId: team.id,
            toTeamId: to.id,
          ),
    );
    if (moved) _refresh(ref, key);
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
    // The club also moves people between teams whose group has not started (control panel).
    final club =
        ref
            .watch(myEventsProvider)
            .value
            ?.where((e) => e.id == key.eventId)
            .firstOrNull
            ?.roles
            .contains(EventRole.club) ??
        false;
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
                wildcard: _asWildcard(all[i]) >= 0
                    ? PickState.ghost
                    : _canJoinAsWildcard(all[i], all)
                    ? PickState.free
                    : null,
                onTap: () => _tapTeam(all[i], all),
                onDelete: all[i].isTaken ? null : () => _delete(all[i]),
                onMoveMember: club && all.length > 1
                    ? () => _moveMember(all[i], all)
                    : null,
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
      ghostTeamLabel: (people) =>
          _ghostTeamLabel(people, teams.value ?? const []),
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
    this.onMoveMember,
    this.wildcard,
  });

  final Team team;
  final DraftGroup group;

  /// In wildcard mode, a team of another group: [PickState.ghost] if it is in this draft as a
  /// wildcard team, [PickState.free] if it can join as one; null otherwise.
  final PickState? wildcard;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onUndoGroup;

  /// The club's: move one of its people to another team.
  final VoidCallback? onMoveMember;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = wildcard ?? group.stateOf(team.id, grouped: team.isTaken);
    final names = team.members
        .map((m) => m.ghost ? l10n.ghostMemberName(m.fullName) : m.fullName)
        .join(', ');
    final grouped = team.isGrouped
        ? l10n.participantGrouped(
            team.groupNumber!,
            matLabel(l10n, team.matNumber),
          )
        : null;
    return ListTile(
      enabled: state != PickState.unavailable,
      onTap: onTap,
      leading: PickMark(state: state, onTap: onTap),
      title: Text(l10n.teamName(team.number)),
      subtitle: Text(
        [
          names,
          if (wildcard != null)
            [?grouped, l10n.teamJoinsAsWildcard].join(' · ')
          else
            ?grouped,
        ].join('\n'),
      ),
      isThreeLine: team.isGrouped,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onMoveMember != null)
            IconButton(
              tooltip: l10n.controlMoveMember,
              icon: const Icon(Icons.swap_horiz),
              onPressed: onMoveMember,
            ),
          if (onDelete != null)
            IconButton(
              tooltip: l10n.deleteTeam,
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            )
          else if (onUndoGroup != null)
            IconButton(
              tooltip: l10n.undoGroupNumber(team.groupNumber!),
              icon: const Icon(Icons.undo),
              onPressed: onUndoGroup,
            ),
        ],
      ),
    );
  }
}

/// Any 2 or 3 participants of the category, except those already in the group: a page of its own,
/// with a search, to make a wildcard team that does not exist as a team.
class _GhostTeamPage extends ConsumerStatefulWidget {
  const _GhostTeamPage({required this.categoryKey, required this.excluded});

  final CategoryKey categoryKey;
  final Set<String> excluded;

  @override
  ConsumerState<_GhostTeamPage> createState() => _GhostTeamPageState();
}

class _GhostTeamPageState extends ConsumerState<_GhostTeamPage> {
  var _picks = <String>[];
  var _search = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final participants = ref.watch(
      categoryParticipantsProvider(widget.categoryKey),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ghostTeamPageTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.m,
              AppSpacing.m,
              AppSpacing.m,
              0,
            ),
            child: Text(l10n.draftGhostTeamHint(DraftGroup.maxTeam)),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.ghostTeamSearch,
              ),
              onChanged: (text) =>
                  setState(() => _search = text.trim().toLowerCase()),
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
                    if (!widget.excluded.contains(p.id) &&
                        (_search.isEmpty ||
                            p.fullName.toLowerCase().contains(_search) ||
                            _picks.contains(p.id)))
                      p,
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
                      onChanged: picked || _picks.length < DraftGroup.maxTeam
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
                onPressed: _picks.length >= DraftGroup.minTeam
                    ? () => Navigator.of(context).pop(_picks)
                    : null,
                child: Text(
                  l10n.pickGhostTeam(_picks.length, DraftGroup.maxTeam),
                ),
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
            l10n.participantGrouped(
              p.groupNumber!,
              matLabel(l10n, p.matNumber),
            ),
          if (p.isGrouped && p.groupCreatedBy != null)
            l10n.groupCreatedBy(p.groupCreatedBy!),
          if (p.queued) l10n.queuedPending,
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
