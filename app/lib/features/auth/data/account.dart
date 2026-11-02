import 'registration.dart';

/// `GET /me`: the signed-in account as the settings show it.
class Account {
  const Account({
    required this.email,
    required this.emailVerified,
    required this.locale,
    required this.profiles,
    required this.signInMethods,
  });

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    email: json['email'] as String,
    emailVerified: json['emailVerified'] as bool,
    locale: json['locale'] as String,
    profiles: [
      for (final profile in json['profiles'] as List<dynamic>)
        ?AccountProfile.fromJson(profile as Map<String, dynamic>),
    ],
    signInMethods: [
      for (final method in json['signInMethods'] as List<dynamic>)
        SignInMethod.fromJson(method as Map<String, dynamic>),
    ],
  );

  final String email;
  final bool emailVerified;
  final String locale;
  final List<AccountProfile> profiles;
  final List<SignInMethod> signInMethods;

  bool get hasPassword =>
      signInMethods.any((m) => m.method == SignInMethod.password);

  SignInMethod? get google {
    for (final method in signInMethods) {
      if (method.method == SignInMethod.google) return method;
    }
    return null;
  }

  Account withLocale(String locale) => Account(
    email: email,
    emailVerified: emailVerified,
    locale: locale,
    profiles: profiles,
    signInMethods: signInMethods,
  );
}

class AccountProfile {
  const AccountProfile({
    required this.type,
    this.validated = false,
    this.organizationName,
    this.taxId,
  });

  /// Null for a profile type this version of the app does not know: it is left out.
  static AccountProfile? fromJson(Map<String, dynamic> json) {
    final type = profileTypeFromWire(json['type'] as String);
    if (type == null) return null;
    return AccountProfile(
      type: type,
      validated: json['validated'] as bool? ?? false,
      organizationName: json['organizationName'] as String?,
      taxId: json['taxId'] as String?,
    );
  }

  final ProfileType type;

  /// By the superadmin; only organizers need it.
  final bool validated;
  final String? organizationName;
  final String? taxId;
}

class SignInMethod {
  const SignInMethod({required this.method, this.email});

  factory SignInMethod.fromJson(Map<String, dynamic> json) => SignInMethod(
    method: json['method'] as String,
    email: json['email'] as String?,
  );

  static const password = 'PASSWORD';
  static const google = 'GOOGLE';

  final String method;

  /// The provider's email; null for the password.
  final String? email;
}

/// Same name the server gives the attachment (`brackety-data-<UTC date>.json`). The web cannot read
/// its Content-Disposition header (not exposed by CORS), so the app builds it.
String exportFileName(DateTime now) {
  final day = now.toUtc();
  return 'brackety-data-'
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}.json';
}

/// Profile sets an account may hold (docs/modulos/auth.md): any single one, or Helper with
/// Student or with External. The server checks it too.
bool isAllowedProfileSet(Set<ProfileType> types) =>
    types.length == 1 ||
    (types.length == 2 &&
        types.contains(ProfileType.helper) &&
        (types.contains(ProfileType.student) ||
            types.contains(ProfileType.external)));

/// What settings offer to add: the sign-up choices (dev-only ones only in dev) that keep the set
/// allowed. Never an organizer: it needs the organization's name and CIF, only given at sign-up.
List<ProfileType> addableProfiles(
  Account account, {
  required bool devEnvironment,
}) {
  final owned = {for (final profile in account.profiles) profile.type};
  return [
    for (final type in registrationProfiles(devEnvironment: devEnvironment))
      if (!type.isOrganizer &&
          !owned.contains(type) &&
          isAllowedProfileSet({...owned, type}))
        type,
  ];
}
