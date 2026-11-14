import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/admin_api_error.dart';
import '../state/admin_session.dart';
import 'admin_texts.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hidden = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // On success the router leaves this screen when the session changes.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(adminSessionProvider.notifier)
          .login(_email.text, _password.text);
    } on DioException catch (e) {
      if (mounted) {
        _error = loginErrorMessage(
          AppLocalizations.of(context),
          AdminApiError.from(e),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final expired = ref.watch(adminSessionProvider.select((s) => s.expired));
    final error = _error;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.formMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.loginTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.l),
                if (expired && error == null) ...[
                  _Message(l10n.sessionExpired, icon: Icons.info_outline),
                  const SizedBox(height: AppSpacing.l),
                ],
                _form(l10n),
                if (error != null) ...[
                  const SizedBox(height: AppSpacing.m),
                  _Message(error, icon: Icons.error_outline, isError: true),
                ],
                const SizedBox(height: AppSpacing.l),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(l10n.loginSubmit),
                ),
                const SizedBox(height: AppSpacing.xl),
                const _OtherPages(),
                const SizedBox(height: AppSpacing.s),
                const AppVersionText(textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _form(AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: l10n.emailLabel),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: AppSpacing.m),
            TextFormField(
              controller: _password,
              obscureText: _hidden,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _busy ? null : _submit(),
              validator: (value) =>
                  (value ?? '').isEmpty ? l10n.fieldRequired : null,
              decoration: InputDecoration(
                labelText: l10n.passwordLabel,
                suffixIcon: ExcludeFocus(
                  child: IconButton(
                    tooltip: _hidden ? l10n.showPassword : l10n.hidePassword,
                    icon: Icon(
                      _hidden ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _hidden = !_hidden),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An error or notice that does not rely on colour alone (it has an icon).
class _Message extends StatelessWidget {
  const _Message(this.text, {required this.icon, this.isError = false});

  final String text;
  final IconData icon;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isError ? scheme.error : scheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: Text(text, style: TextStyle(color: color)),
        ),
      ],
    );
  }
}

/// Pages that need no session: the connection check and, in debug, the design system.
class _OtherPages extends StatelessWidget {
  const _OtherPages();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.s,
      children: [
        TextButton.icon(
          onPressed: () => context.go('/connection'),
          icon: const Icon(Icons.dns_outlined),
          label: Text(l10n.navConnection),
        ),
        if (kDebugMode)
          TextButton.icon(
            onPressed: () => context.go('/design-system'),
            icon: const Icon(Icons.palette_outlined),
            label: Text(l10n.navDesignSystem),
          ),
      ],
    );
  }
}
