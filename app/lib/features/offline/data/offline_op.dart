import '../../scoreboard/data/match_view.dart';

/// A referee action waiting in the device's queue (docs/modulos/offline.md, "App (APK)").
/// [knownEvents]: the non-automatic actions the device knew of this match before it.
/// [rejected]: the server refused it (a 4xx that is not a review); it stays to be seen.
/// [account]: the account that queued it; null in queues saved before it was kept.
class OfflineOp {
  const OfflineOp({
    required this.opId,
    required this.matchId,
    required this.action,
    required this.at,
    required this.knownEvents,
    this.side,
    this.reason,
    this.rejected = false,
    this.account,
  });

  factory OfflineOp.fromJson(Map<String, dynamic> json) => OfflineOp(
    opId: json['opId'] as String,
    matchId: json['matchId'] as String,
    action: MatchAction.fromWire(json['type'] as String),
    side: sideFromJson(json['side']),
    reason: json['reason'] as String?,
    at: DateTime.parse(json['at'] as String),
    knownEvents: json['knownEvents'] as int,
    rejected: json['rejected'] as bool? ?? false,
    account: json['account'] as String?,
  );

  final String opId;
  final String matchId;
  final MatchAction action;
  final Side? side;
  final String? reason;
  final DateTime at;
  final int knownEvents;
  final bool rejected;
  final String? account;

  OfflineOp asRejected() => _copy(rejected: true, account: account);

  OfflineOp ownedBy(String account) =>
      _copy(rejected: rejected, account: account);

  OfflineOp _copy({required bool rejected, required String? account}) =>
      OfflineOp(
        opId: opId,
        matchId: matchId,
        action: action,
        side: side,
        reason: reason,
        at: at,
        knownEvents: knownEvents,
        rejected: rejected,
        account: account,
      );

  /// The body of `POST /matches/{id}/events`.
  Map<String, dynamic> toRequest() => {
    'type': action.wire,
    'side': sideToJson(side),
    'reason': reason,
    'opId': opId,
    'at': at.toUtc().toIso8601String(),
    'knownEvents': knownEvents,
  };

  Map<String, dynamic> toJson() => {
    ...toRequest(),
    'matchId': matchId,
    'rejected': rejected,
    'account': account,
  };
}
