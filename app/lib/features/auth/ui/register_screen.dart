import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/api_error.dart';
import '../data/registration.dart';
import '../data/tax_id.dart';
import '../state/auth_providers.dart';
import '../state/session_controller.dart';
import 'auth_texts.dart';
import 'widgets/acceptance_checkbox.dart';
import 'widgets/auth_form_page.dart';
import 'widgets/birth_date_field.dart';
import 'widgets/form_message.dart';
import 'widgets/organization_fields.dart';
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
  final _organizationName = TextEditingController();
  final _taxId = TextEditingController();
  // Kept here, not in the fields, so switching profile and back loses nothing.
  ProfileType? _profile;
  DateTime? _birthDate;
  bool _declared = false;
  String? _taxIdError;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _organizationName.dispose();
    _taxId.dispose();
    super.dispose();
  }

  Registration _registration(ProfileType profile) {
    final organizer = profile.isOrganizer;
    return Registration(
      email: _email.text.trim(),
      password: _password.text,
      profile: profile,
      locale: Localizations.localeOf(context).languageCode,
      birthDate: organizer ? null : _birthDate,
      organization: organizer
          ? Organization(
              name: _organizationName.text.trim(),
              taxId: normalizeTaxId(_taxId.text),
            )
          : null,
      representativeDeclaration: organizer,
    );
  }

  Future<void> _submit() async {
    final form = _formKey.currentState!;
    if (_busy || !form.validate()) return;
    final registration = _registration(_profile!);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final signedIn = await ref
          .read(sessionProvider.notifier)
          .register(registration);
      // Signed in, the router takes the user home.
      if (!signedIn && mounted) {
        context.go('/register/sent', extra: registration.email);
      }
    } on DioException catch (e) {
      if (mounted) _showError(ApiError.from(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(ApiError error) {
    final l10n = AppLocalizations.of(context);
    setState(() {
      if (error.status == 400 && error.code == 'INVALID_TAX_ID') {
        _taxIdError = l10n.registerTaxIdInvalid;
      } else {
        _error = apiErrorMessage(l10n, error);
      }
    });
  }

  String? _validateBirthDate(AppLocalizations l10n, DateTime? birthDate) {
    if (birthDate == null) return l10n.fieldRequired;
    final today = ref.read(todayProvider);
    return isOldEnoughToRegister(birthDate, today)
        ? null
        : l10n.registerUnderage;
  }

  Widget _profileFields(AppLocalizations l10n, ProfileType profile) {
    if (profile.isOrganizer) {
      return OrganizationFields(
        key: const ValueKey('organization'),
        name: _organizationName,
        taxId: _taxId,
        taxIdError: _taxIdError,
        onTaxIdChanged: (_) {
          if (_taxIdError != null) setState(() => _taxIdError = null);
        },
        declared: _declared,
        onDeclaredChanged: (value) => _declared = value,
      );
    }
    return BirthDateField(
      key: const ValueKey('birthDate'),
      today: ref.watch(todayProvider),
      initialValue: _birthDate,
      onChanged: (value) => _birthDate = value,
      validator: (value) => _validateBirthDate(l10n, value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = _error;
    final profile = _profile;
    return AuthFormPage(
      title: l10n.registerTitle,
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileSelector(
                  profiles: registrationProfiles(
                    devEnvironment: ref.watch(devEnvironmentProvider),
                  ),
                  initialValue: profile,
                  onChanged: (value) => setState(() => _profile = value),
                  validator: (value) =>
                      value == null ? l10n.registerProfileRequired : null,
                ),
                if (profile != null) ...[
                  const SizedBox(height: AppSpacing.m),
                  _profileFields(l10n, profile),
                ],
                const SizedBox(height: AppSpacing.l),
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
                const SizedBox(height: AppSpacing.s),
                AcceptanceCheckbox(
                  title: l10n.registerAccept,
                  requiredText: l10n.registerAcceptRequired,
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
