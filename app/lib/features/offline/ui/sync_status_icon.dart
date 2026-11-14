import 'dart:async';
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

/// An app bar icon for the referee's screens: offline, rejected actions, or actions the server
/// has not taken for [_patience]. A normal send takes under a second, so it never shows then and
/// nothing on the screen moves. Tapping it explains and offers the CSV rescue for the club.
class SyncStatusIcon extends ConsumerStatefulWidget {
  const SyncStatusIcon({super.key});

  @override
  ConsumerState<SyncStatusIcon> createState() => _SyncStatusIconState();
}

const _patience = Duration(seconds: 5);

class _SyncStatusIconState extends ConsumerState<SyncStatusIcon> {
  Timer? _timer;
  bool _late = false;

  int _unsent(OfflineState s) =>
      [...s.ops, ...s.hidden].where((op) => !op.rejected).length;

  @override
  void initState() {
    super.initState();
    ref.listenManual(offlineSyncProvider.select((s) => _unsent(s) > 0), (
      _,
      waiting,
    ) {
      _timer?.cancel();
      if (!waiting) {
        if (_late) setState(() => _late = false);
        return;
      }
      _timer = Timer(_patience, () => setState(() => _late = true));
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final connected = ref.watch(offlineSyncProvider.select((s) => s.connected));
    final rejected = ref.watch(
      offlineSyncProvider.select((s) => s.rejected.length),
    );
    final unsent = ref.watch(offlineSyncProvider.select(_unsent));
    if (connected && rejected == 0 && !(_late && unsent > 0)) {
      return const SizedBox.shrink();
    }
    final text = [
      connected ? l10n.syncConnected : l10n.syncOffline,
      if (unsent > 0) l10n.syncPending(unsent),
      if (rejected > 0) l10n.syncRejected(rejected),
    ].join(' · ');
    final count = unsent + rejected;
    return Semantics(
      liveRegion: true,
      child: IconButton(
        tooltip: text,
        icon: Badge(
          isLabelVisible: count > 0,
          label: Text('$count'),
          child: Icon(
            !connected
                ? Icons.cloud_off
                : rejected > 0
                ? Icons.error_outline
                : Icons.cloud_upload,
          ),
        ),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const _StatusDialog(),
        ),
      ),
    );
  }
}

class _StatusDialog extends ConsumerWidget {
  const _StatusDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(offlineSyncProvider);
    final unsent = [...s.ops, ...s.hidden].where((op) => !op.rejected).length;
    final rejected = s.rejected.length;
    return AlertDialog(
      scrollable: true,
      actionsOverflowDirection: VerticalDirection.up,
      actionsOverflowButtonSpacing: 8,
      title: Text(s.connected ? l10n.syncConnected : l10n.syncOffline),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.formMaxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.m,
          children: [
            if (unsent > 0) Text(l10n.syncPending(unsent)),
            if (rejected > 0) Text(l10n.syncRejected(rejected)),
            if (unsent > 0) Text(l10n.syncExportBody),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
        if (rejected > 0)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showDialog<void>(
                context: context,
                builder: (_) => const _RejectedDialog(),
              );
            },
            child: Text(l10n.syncRejectedShow),
          ),
        if (unsent > 0)
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
      scrollable: true,
      actionsOverflowDirection: VerticalDirection.up,
      actionsOverflowButtonSpacing: 8,
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
