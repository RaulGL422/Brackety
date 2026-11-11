import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/upload/file_upload.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../scoreboard/data/scoreboard_repository.dart';

/// The club imports the CSV of a referee's device that could not send its actions. The server
/// takes each action once, so importing a file twice changes nothing.
class ImportOpsButton extends ConsumerWidget {
  const ImportOpsButton({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      tooltip: l10n.importOps,
      icon: const Icon(Icons.upload_file_outlined),
      onPressed: () => _import(context, ref),
    );
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final files = await ref.read(pickFilesProvider)(
      accept: '.csv,text/csv',
      multiple: false,
    );
    if (files.isEmpty) return;
    try {
      final result = await ref
          .read(scoreboardRepositoryProvider)
          .importOps(eventId, files.first.bytes);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.importOpsResult(
              result.applied,
              result.duplicates,
              result.inReview,
              result.skipped,
            ),
          ),
        ),
      );
    } on DioException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.importOpsError)));
    }
  }
}
