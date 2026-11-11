import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../auth/state/session_controller.dart';
import '../../auth/ui/widgets/confirm_dialog.dart';
import '../state/offline_sync.dart';

/// "Sign out" by hand: the account's actions not sent yet are lost, so it asks first.
Future<void> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final pending = ref.read(offlineSyncProvider).pendingCount;
  if (pending > 0) {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmAction(
      context,
      body: l10n.logoutPending(pending),
      confirmLabel: l10n.logout,
      destructive: true,
    );
    if (!confirmed) return;
  }
  await ref.read(sessionProvider.notifier).logout();
}
