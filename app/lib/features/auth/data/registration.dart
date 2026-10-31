// Provisional until the legal-paginas module publishes the real texts and versions.
const legalDocumentsVersion = '2026-11-draft';

/// Younger people are registered by a guardian (module perfiles-menores).
const minimumRegistrationAge = 14;

const passwordMinLength = 10;
const passwordMaxLength = 128;

enum ProfileType { club, externalEntity, helper, external, student }

extension on ProfileType {
  String get wireName => switch (this) {
    ProfileType.club => 'CLUB',
    ProfileType.externalEntity => 'EXTERNAL_ENTITY',
    ProfileType.helper => 'HELPER',
    ProfileType.external => 'EXTERNAL',
    ProfileType.student => 'STUDENT',
  };
}

/// Whole years between [birthDate] and [today], as the server counts them.
bool isOldEnoughToRegister(DateTime birthDate, DateTime today) {
  var age = today.year - birthDate.year;
  if (today.month < birthDate.month ||
      (today.month == birthDate.month && today.day < birthDate.day)) {
    age--;
  }
  return age >= minimumRegistrationAge;
}

class Registration {
  const Registration({
    required this.email,
    required this.password,
    required this.birthDate,
    required this.profile,
    required this.locale,
  });

  final String email;
  final String password;
  final DateTime birthDate;
  final ProfileType profile;
  final String locale;

  Map<String, Object> toJson() => {
    'email': email,
    'password': password,
    'birthDate': _isoDate(birthDate),
    'profile': profile.wireName,
    'acceptedTermsVersion': legalDocumentsVersion,
    'acceptedPrivacyVersion': legalDocumentsVersion,
    'locale': locale,
  };

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
