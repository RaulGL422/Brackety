import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../data/account.dart';
import '../../state/account_controller.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/reauth_dialog.dart';
import 'account_action.dart';
import 'settings_section.dart';

/// Google cannot be linked from the app yet (no OAuth client ids): it only shows when the account
/// already has it, with unlink and, since there is then another method, "remove password".
class SignInMethodsSection extends ConsumerWidget {
  const SignInMethodsSection({super.key, required this.account});

  final Account account;

  Future<void> _unlinkGoogle(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmAction(
      context,
      body: l10n.googleUnlinkConfirm,
      confirmLabel: l10n.googleUnlink,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await runAccountAction(
      context,
      () => ref
          .read(accountProvider.notifier)
          .unlinkGoogle(() => confirmIdentity(context)),
      done: l10n.googleUnlinked,
    );
  }

  Future<void> _removePassword(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmAction(
      context,
      title: l10n.passwordRemove,
      body: l10n.passwordRemoveConfirm,
      confirmLabel: l10n.passwordRemove,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await runAccountAction(
      context,
      () => ref
          .read(accountProvider.notifier)
          .removePassword(() => confirmIdentity(context)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final google = account.google;
    return SettingsSection(
      title: l10n.settingsSignInMethods,
      children: [
        if (account.hasPassword)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.password),
            title: Text(l10n.signInPassword),
            trailing: google == null
                ? null
                : TextButton(
                    onPressed: () => _removePassword(context, ref),
                    child: Text(l10n.passwordRemove),
                  ),
          ),
        if (google != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(l10n.signInGoogle),
            subtitle: google.email == null ? null : Text(google.email!),
            trailing: TextButton(
              onPressed: () => _unlinkGoogle(context, ref),
              child: Text(l10n.googleUnlink),
            ),
          ),
      ],
    );
  }
}
