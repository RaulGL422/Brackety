import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/api_error.dart';
import '../state/session_controller.dart';
import 'auth_texts.dart';
import 'widgets/auth_alternative.dart';
import 'widgets/auth_form_page.dart';
import 'widgets/auth_note.dart';
import 'widgets/form_message.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authApiProvider).forgotPassword(_email.text.trim());
      if (mounted) setState(() => _sent = true);
    } on DioException catch (e) {
      if (mounted) {
        setState(
          () => _error = apiErrorMessage(
            AppLocalizations.of(context),
            ApiError.from(e),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _tryAnotherEmail() {
    _email.clear();
    setState(() => _sent = false);
  }

  Widget _sentPage(AppLocalizations l10n) {
    return AuthFormPage(
      title: l10n.forgotTitle,
      children: [
        // The same message whether or not the account exists.
        FormMessage.success(l10n.forgotSentTo(_email.text.trim())),
        const SizedBox(height: AppSpacing.l),
        AuthNote(items: [l10n.checkEmailSpam, l10n.forgotCloseHint]),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: () => context.go('/login'),
          child: Text(l10n.forgotBackToLogin),
        ),
        const SizedBox(height: AppSpacing.m),
        OutlinedButton(
          onPressed: _tryAnotherEmail,
          child: Text(l10n.forgotOtherEmail),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = _error;
    if (_sent) return _sentPage(l10n);
    return AuthFormPage(
      title: l10n.forgotTitle,
      subtitle: l10n.forgotIntro,
      error: error,
      children: [
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(labelText: l10n.emailLabel),
            validator: (value) => validateEmail(l10n, value),
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(l10n.forgotSubmit),
        ),
        const SizedBox(height: AppSpacing.l),
        // Recovering by email cannot help a QR account: it has no email.
        Text(
          l10n.forgotQrHint,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        AuthAlternative(
          question: l10n.forgotRemembered,
          action: l10n.loginSubmit,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
