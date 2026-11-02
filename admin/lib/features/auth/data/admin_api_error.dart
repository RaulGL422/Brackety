import 'package:dio/dio.dart';

/// What the admin needs from a failed call: the status and the problem+json properties it reacts to.
class AdminApiError {
  const AdminApiError({this.status, this.lockId, this.retryAfter});

  factory AdminApiError.from(DioException error) {
    final response = error.response;
    final body = response?.data;
    final lockId = body is Map ? body['lockId'] : null;
    final retryAfter = int.tryParse(
      response?.headers.value('retry-after') ?? '',
    );
    return AdminApiError(
      status: response?.statusCode,
      lockId: lockId is String ? lockId : null,
      retryAfter: retryAfter == null ? null : Duration(seconds: retryAfter),
    );
  }

  /// Null when the server never answered (no network, timeout).
  final int? status;
  final String? lockId;
  final Duration? retryAfter;

  bool get noResponse => status == null;

  /// The superadmin's own failed-login lock (type ADMIN), with its id.
  bool get isLocked => status == 429 && lockId != null;

  /// The per-IP request limiter, not a lock: waiting [retryAfter] is enough.
  bool get isRateLimited => status == 429 && lockId == null;
}
