import 'package:brackety/features/events/data/my_event.dart';
import 'package:brackety/features/staff/data/staff_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// The staff API as the server would answer; records what the screens ask for.
class FakeStaffRepository extends Fake implements StaffRepository {
  FakeStaffRepository({this.pending = const [], this.offered, this.refuse});

  List<Invitation> pending;
  InvitationOffer? offered;

  /// The status each call fails with, when set.
  int? refuse;

  final calls = <String>[];

  void _maybeRefuse() {
    if (refuse case final status?) {
      throw DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: status,
        ),
      );
    }
  }

  @override
  Future<List<Invitation>> invitations(String eventId) async => pending;

  @override
  Future<void> invite(String eventId, String email, StaffRole role) async {
    _maybeRefuse();
    calls.add('invite $email ${role.wire}');
    pending = [
      ...pending,
      Invitation(
        id: 'i${pending.length}',
        email: email,
        role: role,
        expired: false,
      ),
    ];
  }

  @override
  Future<void> cancel(String eventId, String invitationId) async {
    calls.add('cancel $invitationId');
    pending = [
      for (final i in pending)
        if (i.id != invitationId) i,
    ];
  }

  @override
  Future<void> remove(String eventId, String accountId, StaffRole role) async {
    _maybeRefuse();
    calls.add('remove $accountId ${role.wire}');
  }

  @override
  Future<void> setPermissions(
    String eventId,
    String accountId,
    Set<EventPermission> permissions,
  ) async {
    _maybeRefuse();
    final wires = [for (final p in permissions) p.wire]..sort();
    calls.add('permissions $accountId ${wires.join(',')}');
  }

  @override
  Future<InvitationOffer> offer(String token) async {
    final offered = this.offered;
    if (offered == null) {
      throw DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 404),
      );
    }
    return offered;
  }

  @override
  Future<String> accept(String token) async {
    _maybeRefuse();
    calls.add('accept $token');
    return 'e1';
  }
}
