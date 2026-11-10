import 'package:dio/dio.dart';

/// What the app needs from a failed call: the status and the problem+json properties it reacts to.
class ApiError {
  const ApiError({
    this.status,
    this.code,
    this.lockId,
    this.deletesOn,
    this.restoreToken,
    this.retryAfter,
  });

  factory ApiError.from(DioException error) {
    final response = error.response;
    final body = response?.data;
    final json = body is Map ? body : const {};
    final deletesOn = json['deletesOn'];
    final retryAfter = int.tryParse(
      response?.headers.value('retry-after') ?? '',
    );
    return ApiError(
      status: response?.statusCode,
      code: json['code'] as String?,
      lockId: json['lockId'] as String?,
      deletesOn: deletesOn is String ? DateTime.tryParse(deletesOn) : null,
      restoreToken: json['restoreToken'] as String?,
      retryAfter: retryAfter == null ? null : Duration(seconds: retryAfter),
    );
  }

  /// Null when the server never answered (no network, timeout).
  final int? status;
  final String? code;
  final String? lockId;
  final DateTime? deletesOn;
  final String? restoreToken;
  final Duration? retryAfter;

  bool get noResponse => status == null;

  /// Too many failed sign-ins: locked for 15 min, with an id the user can quote to support.
  bool get isLocked => status == 429 && lockId != null;

  /// The per-IP request limiter, not a lock: waiting [retryAfter] is enough.
  bool get isRateLimited => status == 429 && lockId == null;

  /// Suspended by the superadmin: no sign-in until it is lifted.
  bool get isSuspended => status == 403 && code == 'ACCOUNT_SUSPENDED';

  bool get isPendingDeletion =>
      status == 403 &&
      code == 'ACCOUNT_PENDING_DELETION' &&
      deletesOn != null &&
      restoreToken != null;
}
