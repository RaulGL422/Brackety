import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../offline/ui/confirm_sign_out.dart';
import '../../state/account_controller.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/reauth_dialog.dart';
import 'account_action.dart';
import 'settings_section.dart';

class ExportSection extends ConsumerWidget {
  const ExportSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SettingsSection(
      title: l10n.settingsData,
      children: [
        Text(l10n.settingsDataHint),
        const SizedBox(height: AppSpacing.m),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.download_outlined),
            label: Text(l10n.settingsExport),
            onPressed: () => runAccountAction(
              context,
              () => ref
                  .read(accountProvider.notifier)
                  .exportData(() => confirmIdentity(context)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Deleting signs out; the sign-in then says until when the account can be restored.
class DangerZoneSection extends ConsumerWidget {
  const DangerZoneSection({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmAction(
      context,
      title: l10n.deleteAccountTitle,
      body: l10n.deleteAccountBody,
      confirmLabel: l10n.deleteAccount,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await runAccountAction(
      context,
      () => ref
          .read(accountProvider.notifier)
          .deleteAccount(() => confirmIdentity(context)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SettingsSection(
      title: l10n.settingsDanger,
      danger: true,
      children: [
        Text(l10n.deleteAccountHint),
        const SizedBox(height: AppSpacing.m),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            icon: const Icon(Icons.delete_forever_outlined),
            label: Text(l10n.deleteAccount),
            onPressed: () => _delete(context, ref),
          ),
        ),
      ],
    );
  }
}

class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.logout),
      label: Text(AppLocalizations.of(context).settingsLogout),
      onPressed: () => confirmSignOut(context, ref),
    );
  }
}
