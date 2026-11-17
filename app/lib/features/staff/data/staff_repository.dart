import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/session_controller.dart';

final staffRepositoryProvider = Provider<StaffRepository>(
  (ref) => StaffRepository(ref.watch(apiProvider)),
);

/// The roles a club invites (F1-5); the club itself is never invited.
enum StaffRole {
  grouper('GROUPER'),
  referee('REFEREE');

  const StaffRole(this.wire);

  final String wire;

  static StaffRole fromWire(String wire) =>
      values.firstWhere((r) => r.wire == wire);
}

/// A pending invitation. [expired]: the link no longer works; inviting again renews it.
class Invitation {
  const Invitation({
    required this.id,
    required this.email,
    required this.role,
    required this.expired,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) => Invitation(
    id: json['id'] as String,
    email: json['email'] as String,
    role: StaffRole.fromWire(json['role'] as String),
    expired: json['expired'] as bool,
  );

  final String id;
  final String email;
  final StaffRole role;
  final bool expired;
}

/// What an invitation link offers. [forYou]: signed in with the invited email, so it can be accepted.
class InvitationOffer {
  const InvitationOffer({
    required this.eventName,
    required this.eventDate,
    required this.organizer,
    required this.role,
    required this.email,
    required this.forYou,
  });

  factory InvitationOffer.fromJson(Map<String, dynamic> json) =>
      InvitationOffer(
        eventName: json['eventName'] as String,
        eventDate: DateTime.parse(json['eventDate'] as String),
        organizer: json['organizer'] as String,
        role: StaffRole.fromWire(json['role'] as String),
        email: json['email'] as String,
        forYou: json['forYou'] as bool,
      );

  final String eventName;
  final DateTime eventDate;
  final String organizer;
  final StaffRole role;
  final String email;
  final bool forYou;
}

/// The event's helpers and referees with their own accounts (docs/modulos/ayudantes-permisos.md).
class StaffRepository {
  StaffRepository(this._dio);

  final Dio _dio;

  String _invitations(String eventId) => '/api/v1/events/$eventId/invitations';

  Future<List<Invitation>> invitations(String eventId) async {
    final response = await _dio.get<List<dynamic>>(_invitations(eventId));
    return [
      for (final i in response.data!)
        Invitation.fromJson(i as Map<String, dynamic>),
    ];
  }

  Future<void> invite(String eventId, String email, StaffRole role) =>
      _dio.post<void>(
        _invitations(eventId),
        data: {'email': email, 'role': role.wire},
      );

  Future<void> cancel(String eventId, String invitationId) =>
      _dio.delete<void>('${_invitations(eventId)}/$invitationId');

  Future<void> remove(String eventId, String accountId, StaffRole role) =>
      _dio.delete<void>(
        '/api/v1/events/$eventId/staff/$accountId',
        queryParameters: {'role': role.wire},
      );

  /// The token goes in the body: never in a URL the server logs keep.
  Future<InvitationOffer> offer(String token) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/invitations/view',
      data: {'token': token},
    );
    return InvitationOffer.fromJson(response.data!);
  }

  /// The event it joined.
  Future<String> accept(String token) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/invitations/accept',
      data: {'token': token},
    );
    return response.data!['eventId'] as String;
  }
}

final invitationsProvider = FutureProvider.autoDispose
    .family<List<Invitation>, String>(
      retry: (_, _) => null,
      (ref, eventId) => ref.watch(staffRepositoryProvider).invitations(eventId),
    );
