import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/async_view.dart';

import 'package:go_router/go_router.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../importing/data/import_repository.dart';
import '../data/club_models.dart';
import '../data/club_repository.dart';
import '../state/club_providers.dart';
import 'club_panel_screen.dart';
import 'participant_form.dart';

/// The students entered in the event, by name; add, edit or delete them.
class ParticipantsTab extends ConsumerWidget {
  const ParticipantsTab({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = participantsProvider(eventId);
    return AsyncView(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      data: (participants) {
        final sorted = [...participants]
          ..sort(
            (a, b) => '${a.firstName} ${a.lastName}'.toLowerCase().compareTo(
              '${b.firstName} ${b.lastName}'.toLowerCase(),
            ),
          );
        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Wrap(
                spacing: AppSpacing.m,
                runSpacing: AppSpacing.s,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.person_add_alt),
                    label: Text(l10n.participantAdd),
                    onPressed: () => showParticipantForm(context, eventId),
                  ),
                  // Only when this server can read lists (it has an Anthropic key).
                  if (ref.watch(importAvailableProvider(eventId)).value ??
                      false)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.document_scanner_outlined),
                      label: Text(l10n.importButton),
                      onPressed: () =>
                          context.push('/events/$eventId/club/import'),
                    ),
                ],
              ),
            ),
            if (sorted.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Text(l10n.categoriesEmpty, textAlign: TextAlign.center),
              ),
            for (final p in sorted) _ParticipantTile(eventId: eventId, p: p),
          ],
        );
      },
    );
  }
}

class _ParticipantTile extends ConsumerWidget {
  const _ParticipantTile({required this.eventId, required this.p});

  final String eventId;
  final Participant p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final height = p.heightCm == null
        ? l10n.heightUnknown
        : l10n.heightCm(p.heightCm!);
    return ListTile(
      title: Text('${p.firstName} ${p.lastName}'),
      subtitle: Wrap(
        spacing: AppSpacing.s,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            [
              l10n.participantAgeCategory(
                p.age,
                p.categoryName ?? l10n.noCategory,
              ),
              height,
              ?p.organizationName,
            ].join(' · '),
          ),
          if (p.needsGuardian) const _NeedsGuardianChip(),
        ],
      ),
      onTap: () => showParticipantForm(context, eventId, participant: p),
      trailing: IconButton(
        tooltip: l10n.delete,
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _delete(context, ref),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        actionsOverflowDirection: VerticalDirection.up,
        actionsOverflowButtonSpacing: 8,
        title: Text(
          l10n.deleteParticipantTitle('${p.firstName} ${p.lastName}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(clubRepositoryProvider).deleteParticipant(eventId, p.id);
      ref.invalidate(participantsProvider(eventId));
    } on DioException catch (e) {
      toasts.show(saveErrorMessage(l10n, e), kind: ToastKind.error);
    }
  }
}

class _NeedsGuardianChip extends StatelessWidget {
  const _NeedsGuardianChip();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(Icons.warning_amber, color: scheme.onErrorContainer),
      label: Text(AppLocalizations.of(context).needsGuardian),
      labelStyle: TextStyle(color: scheme.onErrorContainer),
      backgroundColor: scheme.errorContainer,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
