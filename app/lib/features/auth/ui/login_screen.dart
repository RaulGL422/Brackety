import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/api_error.dart';
import '../state/session_controller.dart';
import 'auth_texts.dart';
import 'widgets/auth_form_page.dart';
import 'widgets/demo_accounts.dart';
import 'widgets/form_message.dart';
import 'widgets/password_field.dart';
import 'widgets/restore_account_dialog.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.passwordChanged = false});

  /// Coming from a password reset: says the new password is ready.
  final bool passwordChanged;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _login(_email.text, _password.text);
    }
  }

  Future<void> _login(String email, String password) async {
    final error = await _attempt(
      () => ref.read(sessionProvider.notifier).login(email, password),
    );
    if (error == null) return;
    if (error.isPendingDeletion) return _offerRestore(error);
    _showError(
      (l10n) => error.status == 401
          ? l10n.loginInvalid
          : apiErrorMessage(l10n, error),
    );
  }

  Future<void> _offerRestore(ApiError pending) async {
    final restore = await showDialog<bool>(
      context: context,
      builder: (_) => RestoreAccountDialog(deletesOn: pending.deletesOn!),
    );
    if (restore != true || !mounted) return;
    final error = await _attempt(
      () => ref
          .read(sessionProvider.notifier)
          .restoreAccount(pending.restoreToken!),
    );
    if (error == null) return;
    _showError(
      (l10n) => error.status == 401
          ? l10n.restoreExpired
          : apiErrorMessage(l10n, error),
    );
  }

  /// Runs a sign-in with the buttons disabled and returns its failure. On success there is
  /// nothing to do here: the router leaves this screen when the session changes.
  Future<ApiError?> _attempt(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      return null;
    } on DioException catch (e) {
      return ApiError.from(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String Function(AppLocalizations l10n) message) {
    if (!mounted) return;
    setState(() => _error = message(AppLocalizations.of(context)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = _error;
    return AuthFormPage(
      title: l10n.loginTitle,
      children: [
        if (widget.passwordChanged) ...[
          FormMessage.success(l10n.loginPasswordChanged),
          const SizedBox(height: AppSpacing.l),
        ],
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  autofillHints: const [
                    AutofillHints.email,
                    AutofillHints.username,
                  ],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.emailLabel),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: AppSpacing.m),
                PasswordField(
                  controller: _password,
                  label: l10n.passwordLabel,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _busy ? null : _submit(),
                  validator: (value) =>
                      (value ?? '').isEmpty ? l10n.fieldRequired : null,
                ),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.m),
          FormMessage.error(error),
        ],
        const SizedBox(height: AppSpacing.l),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(l10n.loginSubmit),
        ),
        const SizedBox(height: AppSpacing.s),
        TextButton(
          onPressed: () => context.go('/forgot-password'),
          child: Text(l10n.loginForgot),
        ),
        TextButton(
          onPressed: () => context.go('/register'),
          child: Text(l10n.loginNoAccount),
        ),
        if (kDebugMode) ...[
          const SizedBox(height: AppSpacing.xl),
          DemoAccounts(
            onSelected: _busy ? null : (account) => _login(account, account),
          ),
        ],
      ],
    );
  }
}
