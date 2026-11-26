import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../legal/data/legal_repository.dart';
import '../../legal/state/legal_providers.dart';
import '../../legal/ui/legal_links.dart';
import '../../legal/ui/linked_text.dart';
import '../data/api_error.dart';
import '../data/registration.dart';
import '../data/tax_id.dart';
import '../state/auth_providers.dart';
import '../state/session_controller.dart';
import 'auth_texts.dart';
import 'widgets/acceptance_checkbox.dart';
import 'widgets/auth_alternative.dart';
import 'widgets/auth_form_page.dart';
import 'widgets/birth_date_field.dart';
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
  final _acceptance = GlobalKey<FormFieldState<bool>>();
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

  Registration _registration(ProfileType profile, LegalVersions versions) {
    final organizer = profile.isOrganizer;
    return Registration(
      email: _email.text.trim(),
      password: _password.text,
      profile: profile,
      locale: Localizations.localeOf(context).languageCode,
      termsVersion: versions.terms,
      privacyVersion: versions.privacy,
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
    if (_busy) return;
    final invalid = form.validateGranularly();
    if (invalid.isNotEmpty) {
      _showMissing(invalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // A failed load would fail every submit: try again instead.
      if (ref.read(legalVersionsProvider).hasError) {
        ref.invalidate(legalVersionsProvider);
      }
      final versions = await ref.read(legalVersionsProvider.future);
      if (!mounted) return;
      final registration = _registration(_profile!, versions);
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

  /// A long form fails in several places at once: say how many, and scroll to the first.
  void _showMissing(Set<FormFieldState<Object?>> invalid) {
    setState(
      () =>
          _error = AppLocalizations.of(context)
              .registerFormErrors(invalid.length),
    );
    final first = invalid.first.context;
    Scrollable.ensureVisible(
      first,
      alignment: 0.2,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 300),
    );
  }

  void _showError(ApiError error) {
    final l10n = AppLocalizations.of(context);
    setState(() {
      if (error.status == 400 && error.code == 'INVALID_TAX_ID') {
        _taxIdError = l10n.registerTaxIdInvalid;
      } else if (error.status == 409 &&
          error.code == 'LEGAL_VERSION_OUTDATED') {
        // The texts changed while the form was open: the new ones must be accepted.
        ref.invalidate(legalVersionsProvider);
        _acceptance.currentState?.didChange(false);
        _error = l10n.registerLegalOutdated;
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
        club: profile == ProfileType.club,
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
    final organizer = profile?.isOrganizer ?? false;
    // Loaded on open, so the submit rarely waits for it.
    ref.watch(legalVersionsProvider);
    return AuthFormPage(
      title: l10n.registerTitle,
      subtitle: l10n.registerSubtitle,
      error: error,
      children: [
        AutofillForm(
          formKey: _formKey,
          children: [
            ProfileSelector(
              profiles: registrationProfiles(
                devEnvironment: ref.watch(devEnvironmentProvider),
              ),
              value: profile,
              onChanged: (value) => setState(() => _profile = value),
              validator: (value) =>
                  value == null ? l10n.registerProfileRequired : null,
            ),
            if (profile != null && organizer)
              _Section(
                title: profile == ProfileType.club
                    ? l10n.registerSectionClub
                    : l10n.registerSectionOrganization,
                child: _profileFields(l10n, profile),
              ),
            _Section(
              // Without an organization, the birth date joins the email and password.
              title: profile == null || organizer
                  ? l10n.registerSectionAccount
                  : l10n.registerSectionYou,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (profile != null && !organizer) ...[
                    _profileFields(l10n, profile),
                    const SizedBox(height: AppSpacing.l),
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(labelText: l10n.emailLabel),
                    validator: (value) => validateEmail(l10n, value),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  NewPasswordField(
                    controller: _password,
                    label: l10n.passwordLabel,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AcceptanceCheckbox(
              key: _acceptance,
              boxed: true,
              title: const _AcceptanceText(),
              requiredText: l10n.registerAcceptTick,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.l),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(l10n.registerSubmit),
        ),
        AuthAlternative(
          question: l10n.registerHaveAccountQuestion,
          action: l10n.loginSubmit,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}

/// A titled block of the form: «Tu club», «Tu cuenta».
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          child,
        ],
      ),
    );
  }
}

class _AcceptanceText extends StatelessWidget {
  const _AcceptanceText();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final terms = l10n.legalTermsLink;
    final privacy = l10n.legalPrivacyLink;
    return LinkedText(
      text: l10n.registerAccept(terms, privacy),
      links: {
        terms: () => openLegalPage(context, LegalDocumentType.terms),
        privacy: () => openLegalPage(context, LegalDocumentType.privacy),
      },
    );
  }
}
