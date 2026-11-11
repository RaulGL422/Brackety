import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/download/file_download.dart';
import '../../../core/upload/file_upload.dart';
import '../../auth/ui/widgets/confirm_dialog.dart';
import '../state/club_providers.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../events/state/events_providers.dart';
import '../../offline/ui/import_ops_button.dart';
import '../data/club_repository.dart';
import 'mats_tab.dart';
import 'participants_tab.dart';
import 'settings_tab.dart';
import 'standings_tab.dart';
import '../../../core/up_button.dart';

/// What the club sees of its event: live scores, mats, entries and settings.
class ClubPanelScreen extends ConsumerStatefulWidget {
  const ClubPanelScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<ClubPanelScreen> createState() => _ClubPanelScreenState();
}

class _ClubPanelScreenState extends ConsumerState<ClubPanelScreen> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final eventName = ref.watch(myEventProvider(widget.eventId)).value?.name;
    return AdaptiveScaffold(
      leading: UpButton(label: l10n.eventsTitle, fallback: '/'),
      leadingWidth: UpButton.leadingWidth(context),
      title: eventName ?? l10n.eventClubPanel,
      actions: [
        if (kIsWeb) ...[
          ImportOpsButton(eventId: widget.eventId),
          ClubExportMenu(eventId: widget.eventId),
        ],
      ],
      destinations: [
        AdaptiveDestination(
          icon: Icons.leaderboard_outlined,
          label: l10n.clubStandings,
        ),
        AdaptiveDestination(
          icon: Icons.sports_martial_arts,
          label: l10n.clubMats,
        ),
        AdaptiveDestination(
          icon: Icons.people_outline,
          label: l10n.clubParticipants,
        ),
        AdaptiveDestination(
          icon: Icons.settings_outlined,
          label: l10n.clubSettings,
        ),
      ],
      selectedIndex: _tab,
      onSelected: (i) => setState(() => _tab = i),
      body: switch (_tab) {
        0 => StandingsTab(eventId: widget.eventId),
        1 => MatsTab(eventId: widget.eventId),
        2 => ParticipantsTab(eventId: widget.eventId),
        _ => SettingsTab(eventId: widget.eventId),
      },
    );
  }
}

/// Brings the hall's results into this event (the Pi after the phase): counts first, then confirms.
const importResultsAction = 'import-results';

/// The CSVs and the whole event as downloads, and the import of the hall's results (web only, like
/// the CSVs).
class ClubExportMenu extends ConsumerWidget {
  const ClubExportMenu({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    Future<void> export(EventExport export) async {
      final toasts = Toasts.of(context);
      try {
        final file = await ref
            .read(clubRepositoryProvider)
            .export(eventId, export);
        await ref.read(saveFileProvider)(
          file.name,
          file.bytes,
          export.mimeType,
        );
      } on DioException {
        toasts.show(l10n.exportError, kind: ToastKind.error);
      }
    }

    return PopupMenuButton<Object>(
      tooltip: l10n.exportMenu,
      icon: const Icon(Icons.download_outlined),
      onSelected: (value) => value is EventExport
          ? export(value)
          : _importResults(context, ref, eventId),
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
    switch (error.response?.statusCode) {
      409 => l10n.saveConflict,
      400 => l10n.saveInvalid,
      _ => l10n.saveError,
    };
