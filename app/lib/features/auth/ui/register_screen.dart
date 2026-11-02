import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/api_error.dart';
import '../data/registration.dart';
import '../state/auth_providers.dart';
import '../state/session_controller.dart';
import 'auth_texts.dart';
import 'widgets/acceptance_checkbox.dart';
import 'widgets/auth_form_page.dart';
import 'widgets/birth_date_field.dart';
import 'widgets/form_message.dart';
import 'widgets/password_field.dart';
import 'widgets/profile_selector.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  DateTime? _birthDate;
  ProfileType? _profile;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState!;
    if (_busy || !form.validate()) return;
    form.save();
    final email = _email.text.trim();
    final registration = Registration(
      email: email,
      password: _password.text,
      birthDate: _birthDate!,
      profile: _profile!,
      locale: Localizations.localeOf(context).languageCode,
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final signedIn = await ref
          .read(sessionProvider.notifier)
          .register(registration);
      // Signed in, the router takes the user home.
      if (!signedIn && mounted) context.go('/register/sent', extra: email);
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

  String? _validateBirthDate(AppLocalizations l10n, DateTime? birthDate) {
    if (birthDate == null) return l10n.fieldRequired;
    final today = ref.read(todayProvider);
    return isOldEnoughToRegister(birthDate, today)
        ? null
        : l10n.registerUnderage;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = _error;
    return AuthFormPage(
      title: l10n.registerTitle,
      children: [
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
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.emailLabel),
                  validator: (value) => validateEmail(l10n, value),
                ),
                const SizedBox(height: AppSpacing.m),
                PasswordField(
                  controller: _password,
                  label: l10n.passwordLabel,
                  helperText: l10n.passwordHint,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (value) => validateNewPassword(l10n, value),
                ),
                const SizedBox(height: AppSpacing.m),
                BirthDateField(
                  today: ref.watch(todayProvider),
                  validator: (value) => _validateBirthDate(l10n, value),
                  onSaved: (value) => _birthDate = value,
                ),
                const SizedBox(height: AppSpacing.l),
                ProfileSelector(
                  profiles: registrationProfiles(
                    devEnvironment: ref.watch(devEnvironmentProvider),
                  ),
                  validator: (value) =>
                      value == null ? l10n.registerProfileRequired : null,
                  onSaved: (value) => _profile = value,
                ),
                const SizedBox(height: AppSpacing.s),
                AcceptanceCheckbox(),
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
          child: Text(l10n.registerSubmit),
        ),
        const SizedBox(height: AppSpacing.s),
        TextButton(
          onPressed: () => context.go('/login'),
          child: Text(l10n.registerHaveAccount),
        ),
      ],
    );
  }
}
