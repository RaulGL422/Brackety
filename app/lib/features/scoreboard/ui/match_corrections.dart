import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/match_view.dart';
import '../data/tambo_match.dart';
import '../state/match_controller.dart';
import 'reason_dialog.dart';

/// A match started by mistake goes back to pending, all at 0; asks why first. The reason and who did it
/// stay in its timeline.
Future<void> cancelMatch(BuildContext context, WidgetRef ref, String matchId) =>
    _correct(context, ref, matchId, MatchAction.cancel);

/// A finished match opens again to correct it; asks why first.
Future<void> reopenMatch(BuildContext context, WidgetRef ref, String matchId) =>
    _correct(context, ref, matchId, MatchAction.reopen);

Future<void> _correct(
  BuildContext context,
  WidgetRef ref,
  String matchId,
  MatchAction action,
) async {
  final l10n = AppLocalizations.of(context);
  final toasts = Toasts.of(context);
  final cancel = action == MatchAction.cancel;
  final reason = await askReason(
    context,
    title: cancel ? l10n.cancelMatchTitle : l10n.reopenMatchTitle,
    confirmLabel: cancel ? l10n.cancelMatch : l10n.reopenMatch,
    destructive: cancel,
  );
  if (reason == null || !context.mounted) return;
  // From the board the match is not open: keep it loaded while the action goes in.
  final provider = matchControllerProvider(matchId);
  final keep = ref.listenManual(provider, (_, _) {});
  try {
    await ref.read(provider.future);
    final refused = await ref
        .read(provider.notifier)
        .send(action, reason: reason);
    if (refused == null) {
      toasts.show(
        cancel ? l10n.cancelMatchDone : l10n.reopenMatchDone,
        kind: ToastKind.success,
      );
    } else {
      toasts.show(
        refused.local == MatchRefusal.matBusy
            ? l10n.refusalMatBusy
            : refused.local == MatchRefusal.notStarted
            ? l10n.refusalNotStarted
            : l10n.actionRefused(refused.detail ?? ''),
        kind: ToastKind.error,
      );
    }
  } finally {
    keep.close();
  }
}
