import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/up_button.dart';
import '../../../core/upload/file_upload.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../events/data/my_event.dart';
import '../../events/state/events_providers.dart';
import '../../league/ui/phase_switcher.dart';
import '../../offline/ui/import_ops_button.dart';
import '../../phase/ui/phase_bar.dart';
import '../data/club_repository.dart';
import '../state/club_providers.dart';
import 'export_download.dart';
import 'mats_tab.dart';
import 'participants_tab.dart';
import 'settings_tab.dart';
import 'standings_tab.dart';

/// What the club sees of a phase: live scores, mats, entries and settings; and its league. A helper
/// sees the tabs their permissions open (F1-7 C): the mats to watch, control or review, and the
/// participants.
class ClubPanelScreen extends ConsumerStatefulWidget {
  const ClubPanelScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<ClubPanelScreen> createState() => _ClubPanelScreenState();
}

enum _PanelTab { standings, mats, participants, settings }

class _ClubPanelScreenState extends ConsumerState<ClubPanelScreen> {
  var _tab = _PanelTab.standings;
  final _settingsUnsaved = ValueNotifier(false);

  @override
  void dispose() {
    _settingsUnsaved.dispose();
    super.dispose();
  }

  /// With unsaved settings, asks before leaving them; leaving drops them.
  Future<bool> _mayLeave() async {
    if (!_settingsUnsaved.value) return true;
    final l10n = AppLocalizations.of(context);
    final leave = await confirmAction(
      context,
      body: l10n.settingsLeaveUnsaved,
      confirmLabel: l10n.settingsLeaveWithoutSaving,
      destructive: true,
    );
    if (leave) _settingsUnsaved.value = false;
    return leave;
  }

  Future<void> _leave(VoidCallback go) async {
    if (await _mayLeave() && mounted) go();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(myEventProvider(widget.eventId)).value;
    final isClub = me?.isClub ?? false;
    final tabs = [
      if (isClub) _PanelTab.standings,
      if (me?.watchesMats ?? false) _PanelTab.mats,
      if (me?.can(EventPermission.participants) ?? false)
        _PanelTab.participants,
      if (isClub) _PanelTab.settings,
    ];
    final tab = tabs.contains(_tab) ? _tab : tabs.firstOrNull;
    final title = me?.name ?? l10n.eventClubPanel;
    // A phase is entered from its league: back goes there; a helper's, to their events.
    final fallback = isClub ? '/leagues/${widget.eventId}' : '/';
    final leading = UpButton(
      label: isClub ? l10n.clubLeague : l10n.eventsTitle,
      fallback: fallback,
      onPressed: () => _leave(() => UpButton.go(context, fallback)),
    );
    final actions = [
      if (isClub) PhaseSwitcher(eventId: widget.eventId, mayLeave: _mayLeave),
      if (kIsWeb) ...[
        if (me?.can(EventPermission.deviceImport) ?? false)
          ImportOpsButton(eventId: widget.eventId),
        if (isClub) ClubExportMenu(eventId: widget.eventId),
      ],
    ];
    final body = Column(
      children: [
        PhaseBar(eventId: widget.eventId),
        Expanded(
          child: switch (tab) {
            _PanelTab.standings => StandingsTab(eventId: widget.eventId),
            _PanelTab.mats => MatsTab(eventId: widget.eventId),
            _PanelTab.participants => ParticipantsTab(eventId: widget.eventId),
            _PanelTab.settings => SettingsTab(
              eventId: widget.eventId,
              unsaved: _settingsUnsaved,
            ),
            // Only a device's CSV: the button above.
            null =>
              me == null
                  ? const SizedBox.shrink()
                  : Center(child: Text(l10n.staffPanelOnlyImport)),
          },
        ),
      ],
    );
    // The navigation needs two places at least.
    if (tabs.length < 2) {
      return _guardBack(
        fallback,
        Scaffold(
          appBar: AppBar(
            leading: leading,
            leadingWidth: UpButton.leadingWidth(context),
            title: Text(title),
            actions: actions,
          ),
          body: body,
        ),
      );
    }
    return _guardBack(
      fallback,
      AdaptiveScaffold(
        leading: leading,
        leadingWidth: UpButton.leadingWidth(context),
        title: title,
        actions: actions,
        destinations: [
          for (final t in tabs)
            switch (t) {
              _PanelTab.standings => AdaptiveDestination(
                icon: Icons.leaderboard_outlined,
                label: l10n.clubStandings,
              ),
              _PanelTab.mats => AdaptiveDestination(
                icon: Icons.sports_martial_arts,
                label: l10n.clubMats,
              ),
              _PanelTab.participants => AdaptiveDestination(
                icon: Icons.people_outline,
                label: l10n.clubParticipants,
              ),
              _PanelTab.settings => AdaptiveDestination(
                icon: Icons.settings_outlined,
                label: l10n.clubSettings,
              ),
            },
        ],
        selectedIndex: tabs.indexOf(tab!),
        onSelected: (i) => tabs[i] == tab
            ? null
            : _leave(() => setState(() => _tab = tabs[i])),
        body: body,
      ),
    );
  }

  /// The system's back (Android, a phone's gesture) asks too.
  Widget _guardBack(String fallback, Widget child) => ValueListenableBuilder(
    valueListenable: _settingsUnsaved,
    builder: (context, unsaved, child) => PopScope(
      canPop: !unsaved,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave(() => UpButton.go(context, fallback));
      },
      child: child!,
    ),
    child: child,
  );
}

/// Brings the hall's results into this event (the Pi after the phase): counts first, then confirms.
const importResultsAction = 'import-results';

/// Opens the screen to build an export to measure.
const customExportAction = 'custom-export';

/// The CSVs and the whole event as downloads, and the import of the hall's results (web only, like
/// the CSVs).
class ClubExportMenu extends ConsumerWidget {
  const ClubExportMenu({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<Object>(
      tooltip: l10n.exportMenu,
      icon: const Icon(Icons.download_outlined),
      onSelected: (value) => switch (value) {
        EventExport() => downloadExport(context, ref, eventId, value),
        customExportAction => context.push('/events/$eventId/club/export'),
        _ => _importResults(context, ref, eventId),
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: EventExport.standings,
          child: Text(l10n.exportStandings),
        ),
        PopupMenuItem(
          value: EventExport.participants,
          child: Text(l10n.exportParticipants),
        ),
        PopupMenuItem(
          value: EventExport.matches,
          child: Text(l10n.exportMatches),
        ),
        PopupMenuItem(
          value: EventExport.timeline,
          child: Text(l10n.exportTimeline),
        ),
        PopupMenuItem(
          value: customExportAction,
          child: ListTile(
            leading: const Icon(Icons.tune),
            title: Text(l10n.exportCustom),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: EventExport.full,
          child: ListTile(
            leading: const Icon(Icons.folder_zip_outlined),
            title: Text(l10n.exportFull),
          ),
        ),
        PopupMenuItem(
          value: importResultsAction,
          child: ListTile(
            leading: const Icon(Icons.upload_file_outlined),
            title: Text(l10n.importResults),
          ),
        ),
      ],
    );
  }
}

Future<void> _importResults(
  BuildContext context,
  WidgetRef ref,
  String eventId,
) async {
  final l10n = AppLocalizations.of(context);
  final toasts = Toasts.of(context);
  final picked = await ref.read(pickFilesProvider)(
    accept: '.zip,.brackety',
    multiple: false,
  );
  if (picked.isEmpty) return;
  final repository = ref.read(clubRepositoryProvider);
  try {
    final counts = await repository.importResults(
      eventId,
      picked.single.bytes,
      dryRun: true,
    );
    if (counts.alreadyImported) {
      toasts.show(l10n.importResultsAlready);
      return;
    }
    if (!context.mounted) return;
    final confirmed = await confirmAction(
      context,
      title: l10n.importResultsTitle,
      body: l10n.importResultsBody(
        counts.groups,
        counts.matches,
        counts.actions,
        counts.newParticipants,
      ),
      confirmLabel: l10n.importResultsConfirm,
    );
    if (!confirmed) return;
    await repository.importResults(eventId, picked.single.bytes, dryRun: false);
    ref
      ..invalidate(standingsProvider(eventId))
      ..invalidate(matsOverviewProvider(eventId))
      ..invalidate(participantsProvider(eventId))
      ..invalidate(eventSettingsProvider(eventId));
    toasts.show(l10n.importResultsDone, kind: ToastKind.success);
  } on DioException catch (e) {
    final data = e.response?.data;
    final code = data is Map ? data['code'] : null;
    toasts.show(switch ((e.response?.statusCode, code)) {
      (409, 'RESULTS_OTHER_EVENT') => l10n.importResultsOtherEvent,
      (409, _) => l10n.importResultsConflict,
      (400, _) => l10n.importResultsInvalid,
      _ => l10n.importResultsError,
    }, kind: ToastKind.error);
  }
}

/// The message for a failed save: 409 means groups depend on what changed.
String saveErrorMessage(AppLocalizations l10n, DioException error) =>
    phaseErrorMessage(l10n, error) ??
    switch (error.response?.statusCode) {
      409 => l10n.saveConflict,
      400 => l10n.saveInvalid,
      _ => l10n.saveError,
    };
