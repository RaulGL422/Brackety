import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../auth/data/api_error.dart';
import '../../auth/ui/widgets/confirm_dialog.dart';
import '../../scoreboard/ui/reason_dialog.dart';
import '../data/phase_repository.dart';

/// The phase's state on top of the club panel, the helper's categories and the referee's mat (F1-7).
/// The club starts, finishes and reopens it here; the others only see it.
class PhaseBar extends ConsumerWidget {
  const PhaseBar({super.key, required this.eventId, required this.isClub});

  final String eventId;
  final bool isClub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final phase = ref.watch(phaseProvider(eventId)).value;
    if (phase == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final (icon, text, background) = switch (phase.state) {
      PhaseState.notStarted => (
        Icons.hourglass_empty,
        isClub ? l10n.phaseNotStartedClub : l10n.phaseNotStarted,
        scheme.secondaryContainer,
      ),
      PhaseState.inProgress => (
        Icons.play_circle_outline,
        l10n.phaseInProgress,
        scheme.surfaceContainerHigh,
      ),
      PhaseState.finished => (
        Icons.lock_outline,
        l10n.phaseFinished,
        scheme.tertiaryContainer,
      ),
    };
    return Material(
      color: background,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: AppSpacing.s),
            Expanded(child: Text(text)),
            if (isClub)
              switch (phase.state) {
                PhaseState.notStarted => FilledButton(
                  onPressed: () => _run(context, ref, (r) => r.start(eventId)),
                  child: Text(l10n.phaseStart),
                ),
                PhaseState.inProgress => OutlinedButton(
                  onPressed: () => _finish(context, ref, phase),
                  child: Text(l10n.phaseFinish),
                ),
                PhaseState.finished => TextButton(
                  onPressed: () => _reopen(context, ref),
                  child: Text(l10n.phaseReopen),
                ),
              },
          ],
        ),
      ),
    );
  }

  Future<void> _finish(BuildContext context, WidgetRef ref, Phase phase) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmAction(
      context,
      title: l10n.phaseFinishTitle,
      body: phase.pendingMatches > 0
          ? l10n.phaseFinishPending(phase.pendingMatches)
          : l10n.phaseFinishBody,
      confirmLabel: l10n.phaseFinish,
      destructive: phase.pendingMatches > 0,
    );
    if (!confirmed || !context.mounted) return;
    await _run(context, ref, (r) => r.finish(eventId));
  }

  Future<void> _reopen(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final reason = await askReason(
      context,
      title: l10n.phaseReopenTitle,
      confirmLabel: l10n.phaseReopen,
    );
    if (reason == null || reason.trim().isEmpty || !context.mounted) return;
    await _run(context, ref, (r) => r.reopen(eventId, reason.trim()));
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<Phase> Function(PhaseRepository) action,
  ) async {
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    try {
      await action(ref.read(phaseRepositoryProvider));
    } on DioException catch (e) {
      toasts.show(
        phaseErrorMessage(l10n, e) ?? l10n.saveError,
        kind: ToastKind.error,
      );
    }
    ref.invalidate(phaseProvider(eventId));
  }
}

/// The answer of any change refused by the phase's state, or null when it was something else.
String? phaseErrorMessage(AppLocalizations l10n, DioException error) =>
    switch (ApiError.from(error).code) {
      'PHASE_NOT_STARTED' => l10n.phaseNotStartedError,
      'PHASE_FINISHED' => l10n.phaseFinishedError,
      'MATCH_IN_PROGRESS' => l10n.phaseMatchInProgressError,
      _ => null,
    };
