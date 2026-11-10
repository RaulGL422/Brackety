import 'package:dio/dio.dart';

class AdminUserRow {
  const AdminUserRow({
    required this.id,
    required this.email,
    required this.createdAt,
    required this.emailVerified,
    required this.deleted,
    required this.suspended,
    required this.profiles,
    this.organization,
  });

  factory AdminUserRow.fromJson(Map<String, dynamic> json) => AdminUserRow(
    id: json['id'] as String,
    email: json['email'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    emailVerified: json['emailVerified'] as bool,
    deleted: json['status'] == 'DELETED',
    suspended: json['suspended'] as bool,
    profiles: [for (final p in json['profiles'] as List) p as String],
    organization: json['organization'] as String?,
  );

  final String id;
  final String email;
  final DateTime createdAt;
  final bool emailVerified;

  /// Deleted and waiting for the purge (the owner can still restore it).
  final bool deleted;
  final bool suspended;

  /// CLUB, EXTERNAL_ENTITY, HELPER, STUDENT, EXTERNAL.
  final List<String> profiles;
  final String? organization;
}

class AdminUserPage {
  const AdminUserPage({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
  });

  factory AdminUserPage.fromJson(Map<String, dynamic> json) => AdminUserPage(
    items: [
      for (final u in json['items'] as List)
        AdminUserRow.fromJson(u as Map<String, dynamic>),
    ],
    page: json['page'] as int,
    size: json['size'] as int,
    total: json['total'] as int,
  );

  final List<AdminUserRow> items;
  final int page;
  final int size;
  final int total;

  int get pageCount => total == 0 ? 1 : (total + size - 1) ~/ size;
  bool get hasNext => page + 1 < pageCount;
}

class AdminUserDetail {
  const AdminUserDetail({
    required this.user,
    required this.signInMethods,
    required this.ownedEvents,
    required this.staffEvents,
    this.lastSignIn,
    this.suspendedAt,
    this.deletesOn,
  });

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) =>
        json[key] == null ? null : DateTime.parse(json[key] as String);
    return AdminUserDetail(
      user: AdminUserRow.fromJson(json['user'] as Map<String, dynamic>),
      signInMethods: [
        for (final m in json['signInMethods'] as List) m as String,
      ],
      ownedEvents: json['ownedEvents'] as int,
      staffEvents: json['staffEvents'] as int,
      lastSignIn: date('lastSignIn'),
      suspendedAt: date('suspendedAt'),
      deletesOn: date('deletesOn'),
    );
  }

  final AdminUserRow user;

  /// PASSWORD and the linked providers (GOOGLE…).
  final List<String> signInMethods;
  final int ownedEvents;
  final int staffEvents;
  final DateTime? lastSignIn;
  final DateTime? suspendedAt;
  final DateTime? deletesOn;
}

/// The superadmin's view of accounts and what it can do to them (every call is audited).
class UsersApi {
  UsersApi(this._dio);

  final Dio _dio;

  static const _base = '/api/v1/admin/users';

  Future<AdminUserPage> list({
    required String query,
    required int page,
    int size = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _base,
      queryParameters: {'q': query, 'page': page, 'size': size},
    );
    return AdminUserPage.fromJson(response.data!);
  }

  Future<AdminUserDetail> detail(String accountId) async {
    final response = await _dio.get<Map<String, dynamic>>('$_base/$accountId');
    return AdminUserDetail.fromJson(response.data!);
  }

  Future<void> suspend(String accountId, String reason) =>
      _dio.post<void>('$_base/$accountId/suspend', data: {'reason': reason});

  Future<void> unsuspend(String accountId, String reason) =>
      _dio.post<void>('$_base/$accountId/unsuspend', data: {'reason': reason});

  /// Returns the purge day. 409 OWNS_EVENTS when the account owns events.
  Future<DateTime> delete(String accountId, String reason) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_base/$accountId/delete',
      data: {'reason': reason},
    );
    return DateTime.parse(response.data!['deletesOn'] as String);
  }
}
