import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../auth/state/account_controller.dart';
import '../../auth/ui/confirm_sign_out.dart';

enum _AccountItem { settings, changelog, signOut }

/// One labelled button instead of three bare icons: people did not know what each one did.
class AccountMenu extends ConsumerWidget {
  const AccountMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final error = Theme.of(context).colorScheme.error;
    // An account let in by QR has no settings of its own.
    final temporary =
        ref.watch(accountProvider.select((a) => a.value?.temporary)) ?? false;
    // Only against the debug server: what each build brings, to know what to try.
    final debug = ref.watch(debugStatusProvider).value != null;
    return PopupMenuButton<_AccountItem>(
      tooltip: l10n.accountMenu,
      onSelected: (item) => switch (item) {
        _AccountItem.settings => context.push('/settings'),
        _AccountItem.changelog => context.push('/changelog'),
        _AccountItem.signOut => confirmSignOut(context, ref),
      },
      itemBuilder: (_) => [
        if (!temporary)
          PopupMenuItem(
            value: _AccountItem.settings,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.settings_outlined),
              title: Text(l10n.settingsTitle),
            ),
          ),
        if (debug)
          PopupMenuItem(
            value: _AccountItem.changelog,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history),
              title: Text(CoreLocalizations.of(context).changelogMenu),
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _AccountItem.signOut,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            iconColor: error,
            textColor: error,
            leading: const Icon(Icons.logout),
            title: Text(l10n.logout),
          ),
        ),
        // Which version this device runs, at a glance.
        const PopupMenuItem(enabled: false, child: AppVersionText()),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s,
          vertical: AppSpacing.s,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Initials(),
            const SizedBox(width: AppSpacing.s),
            Flexible(
              child: Text(
                l10n.accountMenu,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

/// Who is signed in, at a glance: the initials of the organization, else of the email.
class _Initials extends ConsumerWidget {
  const _Initials();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final account = ref.watch(accountProvider).value;
    final name =
        account?.profiles.map((p) => p.organizationName).nonNulls.firstOrNull ??
        account?.email ??
        '';
    return ExcludeSemantics(
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface,
          borderRadius: BorderRadius.circular(AppRadius.m),
        ),
        child: Text(
          initialsOf(name),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.surface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// «Club Yoseikan Sevilla» → «CY»; «ana@ejemplo.es» → «A».
String initialsOf(String name) {
  final words = name
      .split('@')
      .first
      .split(RegExp(r'[\s._-]+'))
      .where((w) => w.isNotEmpty)
      .toList();
  return words.take(2).map((w) => w.characters.first.toUpperCase()).join();
}
