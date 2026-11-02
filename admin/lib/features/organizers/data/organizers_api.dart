import 'package:dio/dio.dart';

enum OrganizerType { club, externalEntity }

class Organizer {
  const Organizer({
    required this.accountId,
    required this.email,
    required this.type,
    required this.validated,
    required this.createdAt,
    this.organizationName,
    this.taxId,
  });

  factory Organizer.fromJson(Map<String, dynamic> json) => Organizer(
    accountId: json['accountId'] as String,
    email: json['email'] as String,
    type: json['profileType'] == 'CLUB'
        ? OrganizerType.club
        : OrganizerType.externalEntity,
    validated: json['validated'] as bool,
    createdAt: DateTime.parse(json['createdAt'] as String),
    organizationName: json['organizationName'] as String?,
    taxId: json['taxId'] as String?,
  );

  final String accountId;
  final String email;
  final OrganizerType type;
  final bool validated;

  /// When the account took the organizer profile.
  final DateTime createdAt;

  /// Null for organizers created before the sign-up asked for name and CIF.
  final String? organizationName;
  final String? taxId;

  Organizer asValidated() => Organizer(
    accountId: accountId,
    email: email,
    type: type,
    validated: true,
    createdAt: createdAt,
    organizationName: organizationName,
    taxId: taxId,
  );
}

class OrganizersApi {
  OrganizersApi(this._dio);

  final Dio _dio;

  static const _base = '/api/v1/admin/organizers';

  /// [validated] null lists them all.
  Future<List<Organizer>> list({bool? validated}) async {
    final response = await _dio.get<List<dynamic>>(
      _base,
      queryParameters: validated == null ? null : {'validated': validated},
    );
    return [
      for (final json in response.data!)
        Organizer.fromJson(json as Map<String, dynamic>),
    ];
  }

  /// Idempotent; the first time the organizer gets an email. 404 if it is no longer an organizer.
  Future<void> validate(String accountId) =>
      _dio.post<void>('$_base/$accountId/validate');
}
