import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/download/file_download.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/club_repository.dart';

/// Downloads one of [eventId]'s exports, with a toast if it fails.
Future<void> downloadExport(
  BuildContext context,
  WidgetRef ref,
  String eventId,
  EventExport export,
) async {
  final l10n = AppLocalizations.of(context);
  final toasts = Toasts.of(context);
  try {
    final file = await ref.read(clubRepositoryProvider).export(eventId, export);
    await ref.read(saveFileProvider)(file.name, file.bytes, export.mimeType);
  } on DioException {
    toasts.show(l10n.exportError, kind: ToastKind.error);
  }
}
