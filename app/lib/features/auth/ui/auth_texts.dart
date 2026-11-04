import '../../../l10n/gen/app_localizations.dart';
import '../data/api_error.dart';
import '../data/registration.dart';
import '../data/tax_id.dart';

/// The message for the failures every auth screen can get; screens handle their own cases first.
String apiErrorMessage(AppLocalizations l10n, ApiError error) {
  if (error.noResponse) return l10n.noServer;
  if (error.isLocked) return l10n.loginLocked(error.lockId!);
  if (error.isRateLimited) {
    final wait = error.retryAfter;
    return wait == null
        ? l10n.tooManyRequestsWait
        : l10n.tooManyRequests(wait.inSeconds);
  }
  return l10n.unexpectedError;
}

String? validateEmail(AppLocalizations l10n, String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return l10n.fieldRequired;
  if (!email.contains('@')) return l10n.emailInvalid;
  return null;
}

String? validateNewPassword(AppLocalizations l10n, String? value) {
  final length = value?.length ?? 0;
  if (length < passwordMinLength) return l10n.passwordTooShort;
  if (length > passwordMaxLength) return l10n.passwordTooLong;
  return null;
}

String? validateOrganizationName(AppLocalizations l10n, String? value) {
  final length = value?.trim().length ?? 0;
  if (length == 0) return l10n.fieldRequired;
  if (length < organizationNameMinLength ||
      length > organizationNameMaxLength) {
    return l10n.registerOrganizationNameLength;
  }
  return null;
}

String? validateTaxId(AppLocalizations l10n, String? value) {
  final taxId = normalizeTaxId(value ?? '');
  if (taxId.isEmpty) return l10n.fieldRequired;
  return isValidCif(taxId) ? null : l10n.registerTaxIdInvalid;
}

String profileName(AppLocalizations l10n, ProfileType profile) =>
    switch (profile) {
      ProfileType.club => l10n.profileClub,
      ProfileType.externalEntity => l10n.profileExternalEntity,
      ProfileType.helper => l10n.profileHelper,
      ProfileType.external => l10n.profileExternal,
      ProfileType.student => l10n.profileStudent,
    };

String profileHint(AppLocalizations l10n, ProfileType profile) =>
    switch (profile) {
      ProfileType.club => l10n.profileClubHint,
      ProfileType.externalEntity => l10n.profileExternalEntityHint,
      ProfileType.helper => l10n.profileHelperHint,
      ProfileType.external => l10n.profileExternalHint,
      ProfileType.student => l10n.profileStudentHint,
    };
