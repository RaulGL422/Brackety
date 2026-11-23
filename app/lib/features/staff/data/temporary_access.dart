import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/session_controller.dart';
import 'staff_repository.dart';

/// Someone let in by QR for this event (a temporary account). [signIn]: its account's sign-in;
/// [waiting]: its code is unused; [signedInAt]: when it was used; [link] and [password]: only right
/// after creating or renewing it, for the QR and to sign in again by hand.
class TemporaryAccess {
  const TemporaryAccess({
    required this.id,
    required this.accountId,
    required this.name,
    required this.role,
    required this.waiting,
    required this.ended,
    this.mat,
    this.signedInAt,
    this.link,
    this.signIn,
    this.password,
  });

  factory TemporaryAccess.fromJson(Map<String, dynamic> json) =>
      TemporaryAccess(
        id: json['id'] as String,
        accountId: json['accountId'] as String,
        name: json['name'] as String,
        role: StaffRole.fromWire(json['role'] as String),
        mat: json['mat'] as int?,
        waiting: json['waiting'] as bool,
        signedInAt: switch (json['signedInAt']) {
          final String at => DateTime.parse(at),
          _ => null,
        },
        ended: json['ended'] as bool,
        link: json['link'] as String?,
        signIn: json['signIn'] as String?,
        password: json['password'] as String?,
      );

  final String id;
  final String accountId;
  final String name;
  final StaffRole role;
  final int? mat;
  final bool waiting;
  final DateTime? signedInAt;
  final bool ended;
  final String? link;
  final String? signIn;
  final String? password;
}

/// QR accesses of an event, for its club (docs/modulos/ayudantes-permisos.md).
class TemporaryAccessRepository {
  TemporaryAccessRepository(this._dio);

  final Dio _dio;

  String _base(String eventId) => '/api/v1/events/$eventId/temporary-access';

  Future<List<TemporaryAccess>> list(String eventId) async {
    final response = await _dio.get<List<dynamic>>(_base(eventId));
    return [
      for (final a in response.data!)
        TemporaryAccess.fromJson(a as Map<String, dynamic>),
    ];
  }

  /// [mat]: for a referee, the mat they take.
  Future<TemporaryAccess> create(
    String eventId, {
    required String name,
    required StaffRole role,
    int? mat,
  }) => _one(
    _dio.post<Map<String, dynamic>>(
      _base(eventId),
      data: {'name': name, 'role': role.wire, 'mat': ?mat},
    ),
  );

  /// A new code: whoever used the old one is signed out.
  Future<TemporaryAccess> renew(String eventId, String accessId) => _one(
    _dio.post<Map<String, dynamic>>('${_base(eventId)}/$accessId/renew'),
  );

  Future<TemporaryAccess> end(String eventId, String accessId) =>
      _one(_dio.post<Map<String, dynamic>>('${_base(eventId)}/$accessId/end'));

  Future<TemporaryAccess> _one(
    Future<Response<Map<String, dynamic>>> request,
  ) async => TemporaryAccess.fromJson((await request).data!);
}

final temporaryAccessRepositoryProvider = Provider<TemporaryAccessRepository>(
  (ref) => TemporaryAccessRepository(ref.watch(apiProvider)),
);

final temporaryAccessesProvider = FutureProvider.autoDispose
    .family<List<TemporaryAccess>, String>(
      retry: (_, _) => null,
      (ref, eventId) =>
          ref.watch(temporaryAccessRepositoryProvider).list(eventId),
    );
