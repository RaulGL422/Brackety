import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/api_error.dart';
import '../state/auth_providers.dart';
import '../state/session_controller.dart';
import 'auth_texts.dart';
import 'widgets/auth_form_page.dart';
import 'widgets/form_message.dart';
import 'widgets/password_field.dart';

/// Opened from the email link with its token.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.token});

  final String? token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  late bool _invalidLink = (widget.token ?? '').isEmpty;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(sessionProvider.notifier)
          .resetPassword(widget.token!, _password.text);
      if (mounted) context.go('/login?passwordChanged=true');
    } on DioException catch (e) {
      final error = ApiError.from(e);
      if (!mounted) return;
      setState(() {
        if (error.status == 400) {
          _invalidLink = true;
        } else {
          _error = apiErrorMessage(AppLocalizations.of(context), error);
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = _error;
    final linkValid = _invalidLink
        ? const AsyncData(false)
        : ref.watch(resetLinkValidProvider(widget.token!));
    if (linkValid case AsyncData(value: false)) {
      return AuthFormPage(
        title: l10n.resetTitle,
        children: [
          FormMessage.error(l10n.linkInvalid),
          const SizedBox(height: AppSpacing.l),
          FilledButton(
            onPressed: () => context.go('/forgot-password'),
            child: Text(l10n.resetRequestNew),
          ),
        ],
      );
    }
    if (linkValid.isLoading) {
      return AuthFormPage(
        title: l10n.resetTitle,
        children: const [Center(child: CircularProgressIndicator())],
      );
    }
    return AuthFormPage(
      title: l10n.resetTitle,
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PasswordField(
                  controller: _password,
                  label: l10n.resetNewPassword,
                  helperText: l10n.passwordHint,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  validator: (value) => validateNewPassword(l10n, value),
                ),
                const SizedBox(height: AppSpacing.m),
                PasswordField(
                  controller: _confirmation,
                  label: l10n.resetConfirmPassword,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (value) =>
                      value == _password.text ? null : l10n.resetMismatch,
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
          child: Text(l10n.resetSubmit),
        ),
      ],
    );
  }
}
