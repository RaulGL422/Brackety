import 'package:dio/dio.dart';

enum LockType { email, ip, admin }

class Lock {
  const Lock({
    required this.lockId,
    required this.type,
    required this.lockedUntil,
    this.email,
    this.ip,
  });

  factory Lock.fromJson(Map<String, dynamic> json) => Lock(
    lockId: json['lockId'] as String,
    type: switch (json['type']) {
      'EMAIL' => LockType.email,
      'IP' => LockType.ip,
      _ => LockType.admin,
    },
    lockedUntil: DateTime.parse(json['lockedUntil'] as String),
    email: json['email'] as String?,
    ip: json['ip'] as String?,
  );

  final String lockId;
  final LockType type;
  final DateTime lockedUntil;

  /// The account's email, when the locked email has one.
  final String? email;

  /// Only on IP locks.
  final String? ip;
}

class LocksApi {
  LocksApi(this._dio);

  final Dio _dio;

  static const _base = '/api/v1/admin/auth/locks';

  Future<List<Lock>> list() async {
    final response = await _dio.get<List<dynamic>>(_base);
    return [
      for (final json in response.data!)
        Lock.fromJson(json as Map<String, dynamic>),
    ];
  }

  /// 404 when the lock has expired or never existed.
  Future<void> revoke(String lockId) =>
      _dio.delete<void>('$_base/${Uri.encodeComponent(lockId)}');
}
