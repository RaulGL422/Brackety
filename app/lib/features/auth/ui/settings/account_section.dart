import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../data/account.dart';
import '../../state/account_controller.dart';
import '../../state/session_controller.dart';
import '../auth_texts.dart';
import '../widgets/reauth_dialog.dart';
import '../widgets/resend_button.dart';
import 'account_action.dart';
import 'settings_section.dart';

class AccountSection extends ConsumerWidget {
  const AccountSection({super.key, required this.account});

  final Account account;

  Future<void> _changeEmail(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final newEmail = await showDialog<String>(
      context: context,
      builder: (_) => const _ChangeEmailDialog(),
    );
    if (newEmail == null || !context.mounted) return;
    await runAccountAction(
      context,
      () => ref
          .read(accountProvider.notifier)
          .changeEmail(newEmail, () => confirmIdentity(context)),
      done: l10n.changeEmailSent(newEmail.trim()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = BracketyColors.of(context);
    final verified = account.emailVerified;
    return SettingsSection(
      title: l10n.settingsAccount,
      children: [
        Text(account.email, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Icon(
              verified ? Icons.verified_outlined : Icons.error_outline,
              color: verified ? colors.success : colors.warning,
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: Text(
                verified
                    ? l10n.settingsEmailVerified
                    : l10n.settingsEmailUnverified,
              ),
            ),
          ],
        ),
        if (!verified) ...[
          const SizedBox(height: AppSpacing.s),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ResendButton(
              send: ref.read(sessionProvider.notifier).resendVerification,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.m),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.alternate_email),
            label: Text(l10n.settingsChangeEmail),
            onPressed: () => _changeEmail(context, ref),
          ),
        ),
      ],
    );
  }
}

/// Pops the new email.
class _ChangeEmailDialog extends StatefulWidget {
  const _ChangeEmailDialog();

  @override
  State<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<_ChangeEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _email.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      scrollable: true,
      actionsOverflowDirection: VerticalDirection.up,
      actionsOverflowButtonSpacing: 8,
      title: Text(l10n.settingsChangeEmail),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _email,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          decoration: InputDecoration(labelText: l10n.changeEmailNew),
          validator: (value) => validateEmail(l10n, value),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.changeEmailSubmit)),
      ],
    );
  }
}
