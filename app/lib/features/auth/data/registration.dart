/// Younger people are registered by a guardian (module perfiles-menores).
const minimumRegistrationAge = 14;

const passwordMinLength = 10;
const passwordMaxLength = 128;

const organizationNameMinLength = 2;
const organizationNameMaxLength = 200;

enum ProfileType { club, externalEntity, helper, external, student }

extension ProfileTypeOrganizer on ProfileType {
  /// Organizers sign up for an organization: no birth date, but its name, CIF and a declaration.
  bool get isOrganizer =>
      this == ProfileType.club || this == ProfileType.externalEntity;
}

extension ProfileTypeWire on ProfileType {
  String get wireName => switch (this) {
    ProfileType.club => 'CLUB',
    ProfileType.externalEntity => 'EXTERNAL_ENTITY',
    ProfileType.helper => 'HELPER',
    ProfileType.external => 'EXTERNAL',
    ProfileType.student => 'STUDENT',
  };
}

/// Null for a type this version of the app does not know yet.
ProfileType? profileTypeFromWire(String wire) {
  for (final type in ProfileType.values) {
    if (type.wireName == wire) return type;
  }
  return null;
}

/// Profiles offered at sign-up. The others are only tried out in dev until their modules exist.
List<ProfileType> registrationProfiles({required bool devEnvironment}) =>
    devEnvironment
    ? ProfileType.values
    : const [ProfileType.club, ProfileType.helper];

/// Whole years between [birthDate] and [today], as the server counts them.
bool isOldEnoughToRegister(DateTime birthDate, DateTime today) {
  var age = today.year - birthDate.year;
  if (today.month < birthDate.month ||
      (today.month == birthDate.month && today.day < birthDate.day)) {
    age--;
  }
  return age >= minimumRegistrationAge;
}

class Organization {
  const Organization({required this.name, required this.taxId});

  final String name;
  final String taxId;

  Map<String, Object> toJson() => {'name': name, 'taxId': taxId};
}

/// Organizers send [organization] and [representativeDeclaration]; everyone else, [birthDate].
class Registration {
  const Registration({
    required this.email,
    required this.password,
    required this.profile,
    required this.locale,
    required this.termsVersion,
    required this.privacyVersion,
    this.birthDate,
    this.organization,
    this.representativeDeclaration = false,
  });

  final String email;
  final String password;
  final ProfileType profile;
  final String locale;

  /// The versions shown when the box was ticked; the server rejects old ones.
  final String termsVersion;
  final String privacyVersion;
  final DateTime? birthDate;
  final Organization? organization;
  final bool representativeDeclaration;

  Map<String, Object> toJson() {
    final birthDate = this.birthDate;
    final organization = this.organization;
    return {
      'email': email,
      'password': password,
      'profile': profile.wireName,
      if (birthDate != null) 'birthDate': _isoDate(birthDate),
      if (organization != null) 'organization': organization.toJson(),
      if (representativeDeclaration) 'representativeDeclaration': true,
      'acceptedTermsVersion': termsVersion,
      'acceptedPrivacyVersion': privacyVersion,
      'locale': locale,
    };
  }

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
