import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../auth/ui/widgets/confirm_dialog.dart';
import '../../mat/ui/fighter_text.dart';
import '../data/match_view.dart';
import '../state/match_review.dart';
import 'timeline_list.dart';

/// For the club: why a match is in review and what the phone sent.
class ReviewPanel extends StatelessWidget {
  const ReviewPanel({super.key, required this.view});

  final MatchView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final review = view.review!;
    final colors = BracketyColors.of(context);
    final onColor = TextStyle(color: colors.onWarningContainer);
    return Card(
      color: colors.warningContainer,
      margin: const EdgeInsets.all(AppSpacing.l),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.reviewTitle,
              style: Theme.of(context).textTheme.titleMedium?.merge(onColor),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(_reason(l10n, review.reason), style: onColor),
            const SizedBox(height: AppSpacing.s),
            for (final op in review.ops) _ReviewOpTile(view: view, op: op),
          ],
        ),
      ),
    );
  }

  static String _reason(AppLocalizations l10n, ReviewReason reason) =>
      switch (reason) {
        ReviewReason.knownEvents => l10n.reviewReasonKnownEvents,
        ReviewReason.rules => l10n.reviewReasonRules,
        ReviewReason.age => l10n.reviewReasonAge,
        ReviewReason.matBusy => l10n.reviewReasonMatBusy,
        ReviewReason.fighterBusy => l10n.reviewReasonFighterBusy,
        ReviewReason.unknown => l10n.reviewReasonUnknown,
      };
}

/// Apply or discard, each after a confirmation; always in sight at the foot of the screen.
class ReviewButtons extends ConsumerWidget {
  const ReviewButtons({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final busy = ref.watch(matchReviewProvider(matchId));
    return Wrap(
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.block),
          label: Text(l10n.reviewDiscard),
          onPressed: busy
              ? null
              : () => _decide(context, ref, ReviewDecision.discard),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.check),
          label: Text(l10n.reviewApply),
          onPressed: busy
              ? null
              : () => _decide(context, ref, ReviewDecision.apply),
        ),
      ],
    );
  }

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    ReviewDecision decision,
  ) async {
    final l10n = AppLocalizations.of(context);
    final apply = decision == ReviewDecision.apply;
    final confirmed = await confirmAction(
      context,
      title: apply ? l10n.reviewApply : l10n.reviewDiscard,
      body: apply ? l10n.reviewApplyConfirm : l10n.reviewDiscardConfirm,
      confirmLabel: apply ? l10n.reviewApply : l10n.reviewDiscard,
      destructive: !apply,
    );
    if (!confirmed || !context.mounted) return;
    final toasts = Toasts.of(context);
    final outcome = await ref
        .read(matchReviewProvider(matchId).notifier)
        .resolve(decision);
    toasts.show(switch (outcome) {
      null => l10n.unexpectedError,
      _ when !apply => l10n.reviewDiscarded,
      ReviewOutcome(:final applied, :final skipped) => l10n.reviewApplied(
        applied,
        skipped,
      ),
    }, kind: ToastKind.error);
  }
}

/// One action from the phone: what, to whom, who did it and when.
class _ReviewOpTile extends StatelessWidget {
  const _ReviewOpTile({required this.view, required this.op});

  final MatchView view;
  final ReviewOp op;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = BracketyColors.of(context);
    final time = DateFormat.Hms(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final side = op.side;
    final who = side == null
        ? null
        : '${sideLabel(l10n, side)} · ${view.corner(side).title(l10n)}';
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      textColor: colors.onWarningContainer,
      title: Text(actionLabel(l10n, op.action)),
      subtitle: Text([?who, ?op.reason, ?op.actor].join(' · ')),
      trailing: Text(time.format(op.at.toLocal())),
    );
  }
}
