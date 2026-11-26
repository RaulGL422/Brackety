import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/session_controller.dart';

/// The actions this device has not sent yet: signing out loses them. `main` gives the referee's
/// queue (`offlineRegistrations`).
final pendingActionsProvider = Provider<int>((ref) => 0);

/// "Sign out" by hand: the account's actions not sent yet are lost, so it asks first.
Future<void> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final pending = ref.read(pendingActionsProvider);
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
