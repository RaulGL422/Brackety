import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../auth/ui/widgets/confirm_dialog.dart';
import '../../auth/data/api_error.dart';
import '../data/grouping_repository.dart';
import '../state/helper_queue.dart';
import '../state/group_draft.dart';
import '../../mat/ui/mat_label.dart';

/// Sends the group to [matId], or to the mat the server picks if null, and shows which one. Calls
/// [refresh] after creating it or on a conflict (someone else took a participant or team, or the
/// mat lost its referee); returns whether it was created.
Future<bool> createGroup(
  BuildContext context,
  WidgetRef ref, {
  required String eventId,
  required String categoryId,
  required DraftGroup group,
  required String? matId,
  required VoidCallback refresh,
  required String label,
}) async {
  final l10n = AppLocalizations.of(context);
  final toasts = Toasts.of(context);
  try {
    final created = await ref
        .read(groupingRepositoryProvider)
        .create(eventId, categoryId, group, matId: matId);
    refresh();
    if (!context.mounted) return true;
    final undo = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        actionsOverflowDirection: VerticalDirection.up,
        actionsOverflowButtonSpacing: 8,
        title: Text(l10n.groupsCreatedTitle(created.groupNumbers.length)),
        // An icon, not "→": the display font has no arrow.
        content: DefaultTextStyle.merge(
          style: Theme.of(context).textTheme.headlineSmall,
          child: Wrap(
            spacing: AppSpacing.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(created.groupNumbers.map(l10n.draftGroup).join(', ')),
              const Icon(Icons.arrow_forward),
              Text(matLabel(l10n, created.matNumber)),
            ],
          ),
        ),
        actions: [
          // Right after a mistake: the group goes back before anyone starts it.
          if (created.groupIds.length == 1)
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.undoGroup),
            ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
    if (undo == true && context.mounted) {
      await undoGroup(
        context,
        ref,
        eventId: eventId,
        groupId: created.groupIds.single,
        number: created.groupNumbers.single,
        refresh: refresh,
      );
    }
    return true;
  } on DioException catch (e) {
    // Without network it waits on the device and goes when the server answers again.
    if (ApiError.from(e).noResponse) {
      await ref
          .read(helperQueueProvider.notifier)
          .add(
            path: GroupingRepository.groupsPath(eventId),
            body: GroupingRepository.groupBody(categoryId, group, matId: matId),
            label: label,
            people: [
              if (!group.ofTeams) ...group.members,
              for (final t in group.ghostTeams) ...t,
            ],
            teams: [if (group.ofTeams) ...group.members],
          );
      toasts.show(l10n.queuedOffline(label));
      return true;
    }
    final conflict = e.response?.statusCode == 409;
    if (conflict) refresh();
    toasts.show(
      conflict
          ? (ApiError.from(e).code == 'SAME_FIGHTER'
                ? l10n.teamOverlapTitle
                : l10n.groupsConflict)
          : l10n.groupsError,
      kind: ToastKind.error,
    );
    return false;
  }
}

/// Tells the helper how the teams and groups made without network ended once sent.
void listenHelperQueue(BuildContext context, WidgetRef ref) {
  ref.listen(helperQueueProvider.select((q) => q.results), (_, results) {
    if (results.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    for (final r in results) {
      toasts.show(
        r.created ? l10n.queuedSent(r.label) : l10n.queuedRefused(r.label),
        kind: r.created ? ToastKind.success : ToastKind.error,
      );
    }
    ref.read(helperQueueProvider.notifier).shown();
  });
}

/// Asks first, then undoes group [number]: its matches go and its members are free again. Once a
/// match of it has started only the superadmin can (the server answers 409).
Future<void> undoGroup(
  BuildContext context,
  WidgetRef ref, {
  required String eventId,
  required String groupId,
  required int number,
  required VoidCallback refresh,
}) async {
  final l10n = AppLocalizations.of(context);
  final toasts = Toasts.of(context);
  final confirmed = await confirmAction(
    context,
    title: l10n.undoGroupNumber(number),
    body: l10n.undoGroupConfirm(number),
    confirmLabel: l10n.undoGroup,
    destructive: true,
  );
  if (!confirmed) return;
  try {
    await ref.read(groupingRepositoryProvider).undoGroup(eventId, groupId);
    toasts.show(l10n.undoGroupDone(number), kind: ToastKind.success);
  } on DioException catch (e) {
    toasts.show(
      e.response?.statusCode == 409
          ? l10n.undoGroupStarted
          : l10n.undoGroupError,
      kind: ToastKind.error,
    );
  }
  refresh();
}
