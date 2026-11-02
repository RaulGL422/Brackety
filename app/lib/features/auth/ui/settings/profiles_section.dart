import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../data/account.dart';
import '../../data/registration.dart';
import '../../state/account_controller.dart';
import '../../state/auth_providers.dart';
import '../auth_texts.dart';
import '../widgets/confirm_dialog.dart';
import 'account_action.dart';
import 'settings_section.dart';

class ProfilesSection extends ConsumerWidget {
  const ProfilesSection({super.key, required this.account});

  final Account account;

  Future<void> _add(BuildContext context, WidgetRef ref, ProfileType type) =>
      runAccountAction(
        context,
        () => ref.read(accountProvider.notifier).addProfile(type),
        done: AppLocalizations.of(context).profileAdded,
      );

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    ProfileType type,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmAction(
      context,
      body: l10n.profileRemoveConfirm(profileName(l10n, type)),
      confirmLabel: l10n.removeAction,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await runAccountAction(
      context,
      () => ref.read(accountProvider.notifier).removeProfile(type),
      done: l10n.profileRemoved,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final addable = addableProfiles(
      account,
      devEnvironment: ref.watch(devEnvironmentProvider),
    );
    return SettingsSection(
      title: l10n.settingsProfiles,
      children: [
        for (final profile in account.profiles)
          _ProfileTile(
            profile: profile,
            // The last one cannot go (409 LAST_PROFILE): no button to invite it.
            onRemove: account.profiles.length > 1
                ? () => _remove(context, ref, profile.type)
                : null,
          ),
        if (addable.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.m),
          Text(l10n.profileAdd, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.s),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              for (final type in addable)
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(profileName(l10n, type)),
                  onPressed: () => _add(context, ref, type),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.profile, required this.onRemove});

  final AccountProfile profile;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final organizer = profile.type.isOrganizer;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(profileName(l10n, profile.type)),
      subtitle: organizer ? _OrganizerDetails(profile: profile) : null,
      trailing: onRemove == null
          ? null
          : IconButton(
              tooltip: l10n.profileRemove,
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: onRemove,
            ),
    );
  }
}

/// The organization and whether the superadmin has validated it (icon and text, not colour alone).
class _OrganizerDetails extends StatelessWidget {
  const _OrganizerDetails({required this.profile});

  final AccountProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = BracketyColors.of(context);
    final name = profile.organizationName;
    final taxId = profile.taxId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (name != null) Text(name),
        if (taxId != null) Text(l10n.profileTaxId(taxId)),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Icon(
              profile.validated ? Icons.verified_outlined : Icons.schedule,
              color: profile.validated ? colors.success : colors.warning,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                profile.validated
                    ? l10n.profileValidated
                    : l10n.profilePendingValidation,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
