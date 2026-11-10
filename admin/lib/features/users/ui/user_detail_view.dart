import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/async_view.dart';
import '../../../core/reason_dialog.dart';
import '../../../core/run_action.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/users_api.dart';
import '../state/users_controller.dart';
import 'users_screen.dart';

/// One account: what it is and has, and what the superadmin can do to it.
class UserDetailView extends ConsumerWidget {
  const UserDetailView({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(userDetailProvider(accountId));
    final refresh = ref.read(userDetailProvider(accountId).notifier).refresh;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l10n.userBack,
              icon: const Icon(Icons.arrow_back),
              onPressed: ref.read(selectedUserProvider.notifier).close,
            ),
            Expanded(
              child: Text(
                detail.value?.user.email ?? '',
                style: Theme.of(context).textTheme.headlineSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: l10n.refresh,
              icon: const Icon(Icons.refresh),
              onPressed: refresh,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        Expanded(
          child: AsyncView(
            value: detail,
            onRetry: refresh,
            data: (user) => _Detail(user),
          ),
        ),
      ],
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail(this.d);

  final AdminUserDetail d;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final user = d.user;
    final facts = [
      (l10n.userColumnState, userState(l10n, user)),
      if (user.organization case final organization?)
        (l10n.userColumnOrganization, organization),
      (l10n.userColumnProfiles, profileNames(l10n, user.profiles)),
      (
        l10n.userSignInMethods,
        d.signInMethods
            .map((m) => m == 'PASSWORD' ? l10n.userPassword : m)
            .join(', '),
      ),
      (l10n.userColumnCreated, l10n.userDate(user.createdAt.toLocal())),
      (
        l10n.userLastSignIn,
        d.lastSignIn == null
            ? l10n.userNever
            : l10n.userDate(d.lastSignIn!.toLocal()),
      ),
      (l10n.userOwnedEvents, '${d.ownedEvents}'),
      (l10n.userStaffEvents, '${d.staffEvents}'),
      if (d.suspendedAt case final at?)
        (l10n.userSuspendedSince, l10n.userDate(at.toLocal())),
      if (d.deletesOn case final on?) (l10n.userDeletesOn, l10n.userDate(on)),
    ];
    return ListView(
      children: [
        for (final (label, value) in facts)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s),
            child: Wrap(
              spacing: AppSpacing.s,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                Text(value),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.l),
        if (!user.deleted)
          Wrap(
            spacing: AppSpacing.m,
            runSpacing: AppSpacing.s,
            children: [
              if (user.suspended)
                OutlinedButton.icon(
                  icon: const Icon(Icons.lock_open),
                  label: Text(l10n.userUnsuspend),
                  onPressed: () => _unsuspend(context, ref),
                )
              else
                OutlinedButton.icon(
                  icon: const Icon(Icons.block),
                  label: Text(l10n.userSuspend),
                  onPressed: () => _suspend(context, ref),
                ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.error,
                  side: BorderSide(color: scheme.error, width: 2),
                ),
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.userDelete),
                onPressed: () => _delete(context, ref),
              ),
            ],
          ),
      ],
    );
  }

  UserDetailController _controller(WidgetRef ref) =>
      ref.read(userDetailProvider(d.user.id).notifier);

  Future<void> _suspend(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final reason = await askReason(
      context,
      title: l10n.userSuspendTitle(d.user.email),
      body: l10n.userSuspendBody,
      confirmLabel: l10n.userSuspend,
    );
    if (reason == null || !context.mounted) return;
    await runAction(
      context,
      () => _controller(ref).suspend(reason),
      done: (_) => l10n.userSuspended,
      notFound: l10n.userChanged,
    );
  }

  Future<void> _unsuspend(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final reason = await askReason(
      context,
      title: l10n.userUnsuspendTitle(d.user.email),
      body: l10n.userUnsuspendBody,
      confirmLabel: l10n.userUnsuspend,
    );
    if (reason == null || !context.mounted) return;
    await runAction(
      context,
      () => _controller(ref).unsuspend(reason),
      done: (_) => l10n.userUnsuspended,
      notFound: l10n.userChanged,
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final reason = await askReason(
      context,
      title: l10n.userDeleteTitle(d.user.email),
      body: l10n.userDeleteBody,
      confirmLabel: l10n.userDelete,
      typeToConfirm: d.user.email,
    );
    if (reason == null || !context.mounted) return;
    await runAction(
      context,
      () => _controller(ref).delete(reason),
      done: (deletesOn) => l10n.userDeleted(deletesOn),
      notFound: l10n.userChanged,
      explain: (error) =>
          error.code == 'OWNS_EVENTS' ? l10n.userOwnsEvents : null,
    );
  }
}
