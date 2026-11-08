import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/grouping_repository.dart';
import '../state/group_draft.dart';

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
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final created = await ref
        .read(groupingRepositoryProvider)
        .create(eventId, categoryId, group, matId: matId);
    refresh();
    if (!context.mounted) return true;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
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
              Text(l10n.matTitle(created.matNumber)),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
    return true;
  } on DioException catch (e) {
    final conflict = e.response?.statusCode == 409;
    if (conflict) refresh();
    messenger.showSnackBar(
      SnackBar(
        content: Text(conflict ? l10n.groupsConflict : l10n.groupsError),
      ),
    );
    return false;
  }
}
