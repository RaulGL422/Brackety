import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/async_view.dart';
import '../../../core/clock.dart';
import '../../../core/confirm_dialog.dart';
import '../../../core/page_header.dart';
import '../../../core/table_line.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/data/admin_api_error.dart';
import '../../auth/ui/admin_texts.dart';
import '../data/locks_api.dart';
import '../state/locks_controller.dart';
import 'lock_tile.dart';

class LocksScreen extends ConsumerWidget {
  const LocksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locks = ref.watch(locksProvider);
    final refresh = ref.read(locksProvider.notifier).refresh;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(title: l10n.locksTitle, onRefresh: refresh),
          const SizedBox(height: AppSpacing.m),
          Expanded(
            child: AsyncView(
              value: locks,
              onRetry: refresh,
              data: (locks) => locks.isEmpty
                  ? Text(l10n.locksEmpty, textAlign: TextAlign.center)
                  : _LockList(locks),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockList extends ConsumerWidget {
  const _LockList(this.locks);

  final List<Lock> locks;

  Future<void> _revoke(BuildContext context, WidgetRef ref, Lock lock) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmAction(
      context,
      title: l10n.lockRevokeTitle(lock.lockId),
      body: l10n.lockRevokeBody,
      confirmLabel: l10n.lockRevoke,
    );
    if (!confirmed || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    String? message;
    try {
      final result = await ref.read(locksProvider.notifier).revoke(lock.lockId);
      message = result == RevokeResult.revoked
          ? l10n.lockRevoked(lock.lockId)
          : l10n.lockAlreadyExpired;
    } on DioException catch (e) {
      message = actionErrorMessage(l10n, AdminApiError.from(e));
    }
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    return LayoutBuilder(
      builder: (context, constraints) =>
          _layout(context, ref, now, constraints.maxWidth >= tableMinWidth),
    );
  }

  Widget _layout(
    BuildContext context,
    WidgetRef ref,
    DateTime now,
    bool table,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (table) ...[
          TableHeader(
            flexes: lockColumns,
            labels: lockColumnLabels(AppLocalizations.of(context)),
          ),
          const Divider(height: 1),
        ],
        Expanded(
          child: ListView.separated(
            itemCount: locks.length,
            separatorBuilder: (_, _) => table
                ? const Divider(height: 1)
                : const SizedBox(height: AppSpacing.s),
            itemBuilder: (context, i) => LockTile(
              lock: locks[i],
              now: now,
              table: table,
              onRevoke: () => _revoke(context, ref, locks[i]),
            ),
          ),
        ),
      ],
    );
  }
}
