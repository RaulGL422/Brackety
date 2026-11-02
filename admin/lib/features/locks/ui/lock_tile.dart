import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

import '../../../core/table_line.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/locks_api.dart';
import 'lock_texts.dart';

/// Column widths of the desktop table: id, type, who, time left, action.
const lockColumns = [2, 2, 4, 4, 2];

List<String> lockColumnLabels(AppLocalizations l10n) => [
  l10n.lockColumnId,
  l10n.lockColumnType,
  l10n.lockColumnWho,
  l10n.lockColumnTimeLeft,
  '',
];

/// A table row on wide windows, a card on phones and tablets.
class LockTile extends StatelessWidget {
  const LockTile({
    super.key,
    required this.lock,
    required this.now,
    required this.onRevoke,
  });

  final Lock lock;
  final DateTime now;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final typeChip = Chip(label: Text(lockTypeName(l10n, lock.type)));
    final revoke = TextButton(
      onPressed: onRevoke,
      child: Text(l10n.lockRevoke),
    );
    final timeLeft = lockTimeLeft(l10n, lock, now);

    if (WindowSize.of(context) == WindowSize.expanded) {
      return TableLine(
        flexes: lockColumns,
        cells: [
          SelectableText(lock.lockId),
          typeChip,
          Text(lockTarget(l10n, lock)),
          Text(timeLeft),
          revoke,
        ],
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [typeChip, SelectableText(lock.lockId)],
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              lockTarget(l10n, lock),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(timeLeft),
            Align(alignment: AlignmentDirectional.centerEnd, child: revoke),
          ],
        ),
      ),
    );
  }
}
