import '../../mat/data/mat_board.dart';

enum Side { red, blue }

enum EndReason { points, time, disqualification }

enum MatchAction {
  start,
  stop,
  point,
  warning,
  oneHandWarning,
  disqualification,
  undo,
  finish;

  String get wire => switch (this) {
    oneHandWarning => 'ONE_HAND_WARNING',
    _ => name.toUpperCase(),
  };

  static MatchAction fromWire(String value) =>
      values.firstWhere((a) => a.wire == value);
}

class Corner {
  const Corner({
    required this.participantId,
    required this.name,
    required this.ghost,
    required this.oneHandRule,
    required this.points,
    required this.warnings,
    required this.oneHandWarnings,
    required this.disqualified,
  });

  factory Corner.fromJson(Map<String, dynamic> json) => Corner(
    participantId: json['participantId'] as String,
    name: json['name'] as String,
    ghost: json['ghost'] as bool,
    oneHandRule: json['oneHandRule'] as bool,
    points: json['points'] as int,
    warnings: json['warnings'] as int,
    oneHandWarnings: json['oneHandWarnings'] as int,
    disqualified: json['disqualified'] as bool,
  );

  final String participantId;
  final String name;
  final bool ghost;

  /// Aged 4 to 7: the one-hand warning applies.
  final bool oneHandRule;
  final int points;
  final int warnings;
  final int oneHandWarnings;
  final bool disqualified;
}

class TimelineEntry {
  const TimelineEntry({
    required this.action,
    required this.at,
    required this.clock,
    required this.automatic,
    required this.undone,
    required this.gaveRivalPoint,
    this.side,
    this.reason,
    this.actor,
  });

  factory TimelineEntry.fromJson(Map<String, dynamic> json) => TimelineEntry(
    action: MatchAction.fromWire(json['type'] as String),
    side: switch (json['side']) {
      'RED' => Side.red,
      'BLUE' => Side.blue,
      _ => null,
    },
    reason: json['reason'] as String?,
    actor: json['actor'] as String?,
    at: DateTime.parse(json['at'] as String),
    clock: Duration(milliseconds: json['clockMs'] as int),
    automatic: json['automatic'] as bool,
    undone: json['undone'] as bool,
    gaveRivalPoint: json['gaveRivalPoint'] as bool,
  );

  final MatchAction action;
  final Side? side;
  final String? reason;
  final String? actor;
  final DateTime at;

  /// Match clock elapsed when it happened.
  final Duration clock;
  final bool automatic;
  final bool undone;
  final bool gaveRivalPoint;
}

class MatchView {
  const MatchView({
    required this.id,
    required this.matId,
    required this.matNumber,
    required this.groupNumber,
    required this.status,
    required this.length,
    required this.pointsLimit,
    required this.remaining,
    required this.running,
    required this.red,
    required this.blue,
    required this.timeline,
    this.endReason,
  });

  factory MatchView.fromJson(Map<String, dynamic> json) => MatchView(
    id: json['id'] as String,
    matId: json['matId'] as String,
    matNumber: json['matNumber'] as int,
    groupNumber: json['groupNumber'] as int,
    status: matchStatusFromJson(json['status'] as String),
    length: Duration(seconds: json['lengthSeconds'] as int),
    pointsLimit: json['pointsLimit'] as int,
    remaining: Duration(milliseconds: json['remainingMs'] as int),
    running: json['running'] as bool,
    endReason: switch (json['endReason']) {
      'POINTS' => EndReason.points,
      'TIME' => EndReason.time,
      'DISQUALIFICATION' => EndReason.disqualification,
      _ => null,
    },
    red: Corner.fromJson(json['red'] as Map<String, dynamic>),
    blue: Corner.fromJson(json['blue'] as Map<String, dynamic>),
    timeline: [
      for (final e in json['timeline'] as List)
        TimelineEntry.fromJson(e as Map<String, dynamic>),
    ],
  );

  final String id;
  final String matId;
  final int matNumber;
  final int groupNumber;
  final MatchStatus status;
  final Duration length;
  final int pointsLimit;

  /// Clock left when the server answered; the screen counts it down while [running].
  final Duration remaining;
  final bool running;
  final EndReason? endReason;
  final Corner red;
  final Corner blue;
  final List<TimelineEntry> timeline;

  Corner corner(Side side) => side == Side.red ? red : blue;

  bool get finished => status == MatchStatus.finished;

  /// Something the referee can still undo: a point, warning or disqualification in force.
  bool get canUndo =>
      !finished &&
      timeline.any(
        (e) =>
            !e.undone &&
            const {
              MatchAction.point,
              MatchAction.warning,
              MatchAction.oneHandWarning,
              MatchAction.disqualification,
            }.contains(e.action),
      );
}
