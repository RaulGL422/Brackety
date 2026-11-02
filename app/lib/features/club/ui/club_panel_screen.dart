import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/download/file_download.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../events/state/events_providers.dart';
import '../data/club_repository.dart';
import 'mats_tab.dart';
import 'participants_tab.dart';
import 'settings_tab.dart';
import 'standings_tab.dart';

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
      title: eventName ?? l10n.eventClubPanel,
      actions: [if (kIsWeb) _ExportMenu(eventId: widget.eventId)],
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

class _ExportMenu extends ConsumerWidget {
  const _ExportMenu({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    Future<void> export(CsvExport export) async {
      final messenger = ScaffoldMessenger.of(context);
      final name = switch (export) {
        CsvExport.standings => 'clasificacion.csv',
        CsvExport.matches => 'combates.csv',
        CsvExport.timeline => 'linea-de-tiempo.csv',
      };
      try {
        final bytes = await ref
            .read(clubRepositoryProvider)
            .csv(eventId, export);
        saveFile(name, bytes, 'text/csv');
      } on DioException {
        messenger.showSnackBar(SnackBar(content: Text(l10n.exportError)));
      }
    }

    return PopupMenuButton<CsvExport>(
      tooltip: l10n.exportCsv,
      icon: const Icon(Icons.download_outlined),
      onSelected: export,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: CsvExport.standings,
          child: Text(l10n.exportStandings),
        ),
        PopupMenuItem(
          value: CsvExport.matches,
          child: Text(l10n.exportMatches),
        ),
        PopupMenuItem(
          value: CsvExport.timeline,
          child: Text(l10n.exportTimeline),
        ),
      ],
    );
  }
}

/// The message for a failed save: 409 means groups depend on what changed.
String saveErrorMessage(AppLocalizations l10n, DioException error) =>
    switch (error.response?.statusCode) {
      409 => l10n.saveConflict,
      400 => l10n.saveInvalid,
      _ => l10n.saveError,
    };
