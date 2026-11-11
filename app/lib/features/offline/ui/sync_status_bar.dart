import 'dart:convert';

import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/download/file_download.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../scoreboard/ui/timeline_list.dart';
import '../data/offline_ops_csv.dart';
import '../state/offline_sync.dart';

/// Connected / offline / N actions waiting, under the app bar of the referee's screens. With
/// actions not sent, a button saves them as a CSV for the club (rescue of a device that cannot
/// connect again).
class SyncStatusBar extends ConsumerWidget {
  const SyncStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final connected = ref.watch(offlineSyncProvider.select((s) => s.connected));
    final pending = ref.watch(
      offlineSyncProvider.select((s) => s.pendingCount),
    );
    final rejected = ref.watch(
      offlineSyncProvider.select((s) => s.rejected.length),
    );
    final unsent = ref.watch(
      offlineSyncProvider.select(
        (s) => [...s.ops, ...s.hidden].where((op) => !op.rejected).length,
      ),
    );
    final scheme = Theme.of(context).colorScheme;
    final colors = BracketyColors.of(context);
    final background = connected
        ? scheme.surfaceContainerHighest
        : colors.warningContainer;
    final foreground = connected
        ? scheme.onSurfaceVariant
        : colors.onWarningContainer;
    final text = [
      connected ? l10n.syncConnected : l10n.syncOffline,
      if (pending > 0) l10n.syncPending(pending),
      if (rejected > 0) l10n.syncRejected(rejected),
    ].join(' · ');
    return Material(
      color: background,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              connected
                  ? (pending > 0 ? Icons.cloud_upload : Icons.cloud_done)
                  : Icons.cloud_off,
              color: foreground,
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(text, style: TextStyle(color: foreground)),
              ),
            ),
            if (rejected > 0)
              TextButton(
                onPressed: () => _showRejected(context),
                child: Text(l10n.syncRejectedShow),
              ),
            if (unsent > 0)
              IconButton(
                tooltip: l10n.syncExport,
                color: foreground,
                icon: const Icon(Icons.file_download_outlined),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const _ExportDialog(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showRejected(BuildContext context) {
    showDialog<void>(context: context, builder: (_) => const _RejectedDialog());
  }
}

class _ExportDialog extends ConsumerWidget {
  const _ExportDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.syncExport),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.formMaxWidth),
        child: Text(l10n.syncExportBody),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
        FilledButton(
          onPressed: () async {
            final ops = ref.read(offlineSyncProvider.notifier).unsent;
            final stamp = DateFormat('yyyyMMdd-HHmmss')
                .format(ref.read(deviceClockProvider)());
            await ref.read(saveFileProvider)(
              'brackety-pendientes-$stamp.csv',
              utf8.encode(offlineOpsCsv(ops)),
              'text/csv',
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(l10n.syncExportSave),
        ),
      ],
    );
  }
}

class _RejectedDialog extends ConsumerWidget {
  const _RejectedDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rejected = ref.watch(offlineSyncProvider.select((s) => s.rejected));
    final time = DateFormat.Hms(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return AlertDialog(
      title: Text(l10n.syncRejectedTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.formMaxWidth),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.syncRejectedBody),
              for (final op in rejected)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(actionLabel(l10n, op.action)),
                  subtitle: Text(
                    [?sideLabel(l10n, op.side), ?op.reason].join(' · '),
                  ),
                  trailing: Text(time.format(op.at.toLocal())),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
        FilledButton(
          onPressed: () {
            ref.read(offlineSyncProvider.notifier).dismissRejected();
            Navigator.pop(context);
          },
          child: Text(l10n.syncRejectedDismiss),
        ),
      ],
    );
  }
}
