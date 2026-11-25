import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/staff_repository.dart';
import '../data/temporary_access.dart';
import 'qr_access.dart';

/// The QR accesses of the event and what is still missing: a mat without referee, nobody for
/// the groups. A helper by QR from here; a referee from the QR next to their mat.
class QrAccessSection extends ConsumerWidget {
  const QrAccessSection({
    super.key,
    required this.eventId,
    required this.matReferees,
    required this.hasGrouper,
  });

  final String eventId;
  final List<String?> matReferees;
  final bool hasGrouper;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final withoutReferee = [
      for (final (i, referee) in matReferees.indexed)
        if (referee == null) i + 1,
    ];
    final accesses = ref.watch(temporaryAccessesProvider(eventId)).value ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.qrAccessTitle, style: text.titleMedium),
        Text(l10n.qrAccessSectionHint, style: text.bodySmall),
        if (withoutReferee.isNotEmpty)
          _Warning(l10n.qrAccessMatsWithoutReferee(withoutReferee.join(', '))),
        if (!hasGrouper) _Warning(l10n.qrAccessNoGrouper),
        for (final access in accesses)
          _AccessTile(eventId: eventId, access: access),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            icon: const Icon(Icons.qr_code_2),
            label: Text(l10n.qrAccessCreateHelper),
            onPressed: () =>
                createQrAccess(context, ref, eventId, StaffRole.grouper, null),
          ),
        ),
      ],
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s),
      child: Row(
        spacing: AppSpacing.s,
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.error, size: 20),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _AccessTile extends ConsumerWidget {
  const _AccessTile({required this.eventId, required this.access});

  final String eventId;
  final TemporaryAccess access;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final role = switch (access.mat) {
      final int mat => l10n.qrAccessRefereeOf(mat),
      null when access.role == StaffRole.referee => l10n.qrAccessReferee,
      null => l10n.qrAccessHelper,
    };
    final status = access.ended
        ? l10n.qrAccessEnded
        : access.signedInAt != null
        ? l10n.qrAccessSignedInAt(
            DateFormat.Hm().format(access.signedInAt!.toLocal()),
          )
        : l10n.qrAccessNotYet;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.badge_outlined),
      title: Text(access.name, overflow: TextOverflow.ellipsis),
      subtitle: Text([role, status, ?access.signIn].join(' · ')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            tooltip: l10n.qrAccessRenew,
            onPressed: () => renewQrAccess(context, ref, eventId, access),
          ),
          if (!access.ended)
            IconButton(
              icon: const Icon(Icons.block),
              tooltip: l10n.qrAccessEnd,
              onPressed: () => _end(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _end(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    final confirmed = await confirmAction(
      context,
      body: l10n.qrAccessEndConfirm(access.name),
      confirmLabel: l10n.qrAccessEnd,
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(temporaryAccessRepositoryProvider).end(eventId, access.id);
      refreshQrAccesses(ref, eventId);
    } on DioException catch (e) {
      toasts.show(qrAccessError(l10n, e), kind: ToastKind.error);
    }
  }
}
