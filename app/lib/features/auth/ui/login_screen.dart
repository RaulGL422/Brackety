import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../server/ui/server_tile.dart';
import '../data/api_error.dart';
import '../state/session_controller.dart';
import 'auth_texts.dart';
import 'widgets/auth_alternative.dart';
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

  /// A QR referee's sign-in was offered, but someone else signs in on this device.
  bool _otherAccount = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit({String? signIn}) {
    if (_formKey.currentState!.validate()) {
      _login(signIn ?? _email.text, _password.text);
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

  String _noticeText(AppLocalizations l10n, SignedOutNotice notice) =>
      switch (notice) {
        AccountDeletionScheduled(:final deletesOn) => l10n.loginAccountDeleted(
          DateFormat.yMMMMd(Localizations.localeOf(context).toLanguageTag())
              .format(deletesOn),
        ),
        PasswordRemoved() => l10n.loginPasswordRemoved,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = _error;
    final notice = ref.watch(sessionProvider.select((s) => s.notice));
    final expired = ref.watch(sessionProvider.select((s) => s.expired));
    // A QR referee whose session dropped (GR-2): their sign-in shown, only the password to type,
    // nothing about signing up or a forgotten password, which are not theirs.
    final qrSignIn = expired && !_otherAccount
        ? ref.watch(qrSignInProvider).value
        : null;
    return AuthFormPage(
      title: l10n.loginTitle,
      subtitle: qrSignIn == null ? l10n.loginSubtitle : null,
      children: [
        if (widget.passwordChanged) ...[
          FormMessage.success(l10n.loginPasswordChanged),
          const SizedBox(height: AppSpacing.l),
        ],
        if (notice != null) ...[
          FormMessage.success(_noticeText(l10n, notice)),
          const SizedBox(height: AppSpacing.l),
        ],
        if (qrSignIn != null) ...[
          _QrSessionLost(signIn: qrSignIn),
          const SizedBox(height: AppSpacing.l),
        ],
        // Under the heading, where the eye starts again after the button: what failed comes first.
        if (error != null) ...[
          FormMessage.error(error),
          const SizedBox(height: AppSpacing.l),
        ],
        const ServerTile(),
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (qrSignIn == null) ...[
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    autofillHints: const [
                      AutofillHints.email,
                      AutofillHints.username,
                    ],
                    textInputAction: TextInputAction.next,
                    // A QR account signs in with its `qr-…` sign-in, not an email.
                    decoration: InputDecoration(labelText: l10n.loginUserLabel),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? l10n.fieldRequired
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.m),
                ],
                PasswordField(
                  controller: _password,
                  label: l10n.passwordLabel,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  autofocus: qrSignIn != null,
                  onSubmitted: (_) => _busy ? null : _submit(signIn: qrSignIn),
                  validator: (value) =>
                      (value ?? '').isEmpty ? l10n.fieldRequired : null,
                ),
                // Where it is looked for: right under the password.
                if (qrSignIn == null) const _ForgotPassword(),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        FilledButton(
          onPressed: _busy ? null : () => _submit(signIn: qrSignIn),
          child: Text(l10n.loginSubmit),
        ),
        const SizedBox(height: AppSpacing.s),
        if (qrSignIn != null)
          TextButton(
            onPressed: () => setState(() => _otherAccount = true),
            child: Text(l10n.loginOtherAccount),
          )
        else
          const _SignUp(),
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

/// Why the referee is here and who they are: not an error of theirs, so no error colour; their
/// sign-in large, to read it against the club's paper if they doubt.
class _QrSessionLost extends StatelessWidget {
  const _QrSessionLost({required this.signIn});

  final String signIn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.s,
        children: [
          Row(
            spacing: AppSpacing.s,
            children: [
              const Icon(Icons.qr_code_2),
              Expanded(
                child: Text(
                  l10n.loginQrLostTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          Text(l10n.loginQrLostBody),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.loginQrUser, style: muted),
          Text(signIn, style: theme.textTheme.headlineSmall),
        ],
      ),
    );
  }
}

/// Right under the password, where it is looked for; its text ends at the field's edge.
class _ForgotPassword extends StatelessWidget {
  const _ForgotPassword();

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerEnd,
    // Still 48 px tall to tap.
    child: TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      ),
      onPressed: () => context.go('/forgot-password'),
      child: Text(AppLocalizations.of(context).loginForgot),
    ),
  );
}

/// The way to an account, apart from signing in: a question and its own button.
class _SignUp extends StatelessWidget {
  const _SignUp();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AuthAlternative(
      question: l10n.loginNoAccount,
      action: l10n.loginCreateAccount,
      onPressed: () => context.go('/register'),
    );
  }
}
