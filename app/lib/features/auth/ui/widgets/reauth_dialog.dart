import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../data/api_error.dart';
import '../../state/reauth.dart';
import '../auth_texts.dart';
import 'form_message.dart';
import 'password_field.dart';

/// Asks the password before a sensitive action; true once the server has accepted it.
Future<bool> confirmIdentity(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => const ReauthDialog(),
    ) ??
    false;

/// Stays open on a wrong password or a lock, with the reason, so the user can try again or cancel.
class ReauthDialog extends ConsumerStatefulWidget {
  const ReauthDialog({super.key});

  @override
  ConsumerState<ReauthDialog> createState() => _ReauthDialogState();
}

class _ReauthDialogState extends ConsumerState<ReauthDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_password.text.isEmpty || _busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(reauthProvider).confirmPassword(_password.text);
      if (mounted) Navigator.pop(context, true);
    } on DioException catch (e) {
      final error = ApiError.from(e);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.code == 'REAUTH_FAILED'
            ? l10n.reauthFailed
            : apiErrorMessage(l10n, error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = _error;
    return AlertDialog(
      scrollable: true,
      actionsOverflowDirection: VerticalDirection.up,
      actionsOverflowButtonSpacing: 8,
      title: Text(l10n.reauthTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.formMaxWidth),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.reauthBody),
              const SizedBox(height: AppSpacing.l),
              PasswordField(
                controller: _password,
                label: l10n.passwordLabel,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              if (error != null) ...[
                const SizedBox(height: AppSpacing.m),
                FormMessage.error(error),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(l10n.reauthSubmit),
        ),
      ],
    );
  }
}
