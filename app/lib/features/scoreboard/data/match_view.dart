import '../../mat/data/mat_board.dart';

enum Side { red, blue }

enum EndReason { points, time, disqualification }

Side? sideFromJson(Object? value) => switch (value) {
  'RED' => Side.red,
  'BLUE' => Side.blue,
  _ => null,
};

String? sideToJson(Side? side) => side?.name.toUpperCase();

enum MatchAction {
  start,
  stop,
  point,
  pointRemoved,
  warning,
  oneHandWarning,
  disqualification,
  clockAdjust,
  undo,
  finish,

  /// Started by mistake: back to pending, all at 0 (with a reason; the trail stays).
  cancel,

  /// A finished match opens again to correct it (with a reason).
  reopen;

  String get wire => switch (this) {
    oneHandWarning => 'ONE_HAND_WARNING',
    pointRemoved => 'POINT_REMOVED',
    clockAdjust => 'CLOCK_ADJUST',
    _ => name.toUpperCase(),
  };

  static MatchAction fromWire(String value) =>
      values.firstWhere((a) => a.wire == value);
}

class Corner implements FighterInfo {
  const Corner({
    required this.participantId,
    required this.name,
    required this.ghost,
    required this.oneHandRule,
    required this.points,
    required this.warnings,
    required this.oneHandWarnings,
    required this.disqualified,
    this.teamNumber,
    this.members = const [],
  });

  factory Corner.fromJson(Map<String, dynamic> json) => Corner(
    participantId: json['participantId'] as String?,
    name: json['name'] as String,
    ghost: json['ghost'] as bool,
    oneHandRule: json['oneHandRule'] as bool,
    points: json['points'] as int,
    warnings: json['warnings'] as int,
    oneHandWarnings: json['oneHandWarnings'] as int,
    disqualified: json['disqualified'] as bool,
    teamNumber: json['teamNumber'] as int?,
    members: [for (final m in json['members'] as List? ?? []) m as String],
  );

  /// Null for a team.
  final String? participantId;
  @override
  final String name;
  @override
  final bool ghost;
  @override
  final int? teamNumber;
  @override
  final List<String> members;

  /// Aged 4 to 7 (for a team, someone in it): the one-hand warning applies.
  final bool oneHandRule;
  final int points;
  final int warnings;
  final int oneHandWarnings;
  final bool disqualified;

  /// The same fighter with the tally of a replay.
  Corner withTally({
    required int points,
    required int warnings,
    required int oneHandWarnings,
    required bool disqualified,
  }) => Corner(
    participantId: participantId,
    name: name,
    ghost: ghost,
    oneHandRule: oneHandRule,
    points: points,
    warnings: warnings,
    oneHandWarnings: oneHandWarnings,
    disqualified: disqualified,
    teamNumber: teamNumber,
    members: members,
  );

  Map<String, dynamic> toJson() => {
    'participantId': participantId,
    'name': name,
    'ghost': ghost,
    'oneHandRule': oneHandRule,
    'points': points,
    'warnings': warnings,
    'oneHandWarnings': oneHandWarnings,
    'disqualified': disqualified,
    'teamNumber': teamNumber,
    'members': members,
  };
}

class TimelineEntry {
  const TimelineEntry({
    required this.action,
    required this.at,
    required this.clock,
    required this.automatic,
    required this.undone,
    required this.gaveRivalPoint,
    this.id,
    this.side,
    this.reason,
    this.actor,
    this.opId,
    this.delta,
  });

  factory TimelineEntry.fromJson(Map<String, dynamic> json) => TimelineEntry(
    id: json['id'] as String?,
    action: MatchAction.fromWire(json['type'] as String),
    side: sideFromJson(json['side']),
    reason: json['reason'] as String?,
    actor: json['actor'] as String?,
    at: DateTime.parse(json['at'] as String),
    clock: Duration(milliseconds: json['clockMs'] as int),
    automatic: json['automatic'] as bool,
    undone: json['undone'] as bool,
    gaveRivalPoint: json['gaveRivalPoint'] as bool,
    opId: json['opId'] as String?,
    delta: _duration(json['deltaMs']),
  );

  /// The server's event id; for an action still in the device's queue, its `opId`.
  final String? id;

  /// The device action it came from; null for the web and the automatic ones.
  final String? opId;
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

  /// For a clock adjustment: the time added (negative: taken away).
  final Duration? delta;

  TimelineEntry withFlags({
    required bool undone,
    required bool gaveRivalPoint,
  }) => TimelineEntry(
    id: id,
    action: action,
    side: side,
    reason: reason,
    actor: actor,
    at: at,
    clock: clock,
    automatic: automatic,
    undone: undone,
    gaveRivalPoint: gaveRivalPoint,
    opId: opId,
    delta: delta,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': action.wire,
    'side': sideToJson(side),
    'reason': reason,
    'actor': actor,
    'at': at.toUtc().toIso8601String(),
    'clockMs': clock.inMilliseconds,
    'automatic': automatic,
    'undone': undone,
    'gaveRivalPoint': gaveRivalPoint,
    'opId': opId,
    'deltaMs': delta?.inMilliseconds,
  };
}

Duration? _duration(Object? ms) =>
    ms is int ? Duration(milliseconds: ms) : null;

/// Why the first offline action of a match clashed (`review.reason` of the server).
enum ReviewReason { knownEvents, rules, age, matBusy, fighterBusy, unknown }

const _reviewReasons = {
  'KNOWN_EVENTS': ReviewReason.knownEvents,
  'RULES': ReviewReason.rules,
  'AGE': ReviewReason.age,
  'MAT_BUSY': ReviewReason.matBusy,
  'FIGHTER_BUSY': ReviewReason.fighterBusy,
};

/// An action a device sent that the server kept for the club instead of applying it.
class ReviewOp {
  const ReviewOp({
    required this.opId,
    required this.action,
    required this.at,
    required this.receivedAt,
    required this.cause,
    this.side,
    this.reason,
    this.actor,
    this.delta,
  });

  factory ReviewOp.fromJson(Map<String, dynamic> json) => ReviewOp(
    opId: json['opId'] as String,
    action: MatchAction.fromWire(json['type'] as String),
    side: sideFromJson(json['side']),
    reason: json['reason'] as String?,
    actor: json['actor'] as String?,
    at: DateTime.parse(json['at'] as String),
    receivedAt: DateTime.parse(json['receivedAt'] as String),
    cause: json['cause'] as String,
    delta: _duration(json['deltaMs']),
  );

  final String opId;
  final MatchAction action;
  final Side? side;
  final String? reason;
  final String? actor;
  final DateTime at;
  final DateTime receivedAt;
  final String cause;
  final Duration? delta;

  Map<String, dynamic> toJson() => {
    'opId': opId,
    'type': action.wire,
    'side': sideToJson(side),
    'reason': reason,
    'actor': actor,
    'at': at.toUtc().toIso8601String(),
    'receivedAt': receivedAt.toUtc().toIso8601String(),
    'cause': cause,
    'deltaMs': delta?.inMilliseconds,
  };
}

/// The match waits for the club to apply or discard what a device sent.
class MatchReview {
  const MatchReview({required this.reason, required this.ops});

  /// Known only on this device so far (a 409): the details come with the next view.
  const MatchReview.pending() : reason = ReviewReason.unknown, ops = const [];

  factory MatchReview.fromJson(Map<String, dynamic> json) => MatchReview(
    reason: _reviewReasons[json['reason']] ?? ReviewReason.unknown,
    ops: [
      for (final op in json['ops'] as List)
        ReviewOp.fromJson(op as Map<String, dynamic>),
    ],
  );

  final ReviewReason reason;
  final List<ReviewOp> ops;

  Map<String, dynamic> toJson() => {
    'reason': _reviewReasons.entries
        .where((e) => e.value == reason)
        .firstOrNull
        ?.key,
    'ops': [for (final op in ops) op.toJson()],
  };
}

enum ReviewDecision { apply, discard }

/// The club's review done: the match now and how many actions went in or were skipped.
class ReviewOutcome {
  const ReviewOutcome({
    required this.match,
    required this.applied,
    required this.skipped,
  });

  factory ReviewOutcome.fromJson(Map<String, dynamic> json) => ReviewOutcome(
    match: MatchView.fromJson(json['match'] as Map<String, dynamic>),
    applied: json['applied'] as int,
    skipped: json['skipped'] as int,
  );

  final MatchView match;
  final int applied;
  final int skipped;
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
    this.serverTime,
    this.review,
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
    serverTime: switch (json['serverTime']) {
      final String at => DateTime.parse(at),
      _ => null,
    },
    review: switch (json['review']) {
      final Map<String, dynamic> review => MatchReview.fromJson(review),
      _ => null,
    },
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'matId': matId,
    'matNumber': matNumber,
    'groupNumber': groupNumber,
    'status': switch (status) {
      MatchStatus.pending => 'PENDING',
      MatchStatus.inProgress => 'IN_PROGRESS',
      MatchStatus.finished => 'FINISHED',
    },
    'lengthSeconds': length.inSeconds,
    'pointsLimit': pointsLimit,
    'remainingMs': remaining.inMilliseconds,
    'running': running,
    'endReason': switch (endReason) {
      EndReason.points => 'POINTS',
      EndReason.time => 'TIME',
      EndReason.disqualification => 'DISQUALIFICATION',
      null => null,
    },
    'red': red.toJson(),
    'blue': blue.toJson(),
    'timeline': [for (final e in timeline) e.toJson()],
    'serverTime': serverTime?.toUtc().toIso8601String(),
    'review': review?.toJson(),
  };

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

  /// When the server computed this view; null from a server without the offline queue.
  final DateTime? serverTime;

  /// Set while the club has to review what a device sent: nothing more is accepted.
  final MatchReview? review;

  /// What the device counts in `knownEvents`: the automatic stops are left out.
  int get knownEvents => timeline.where((e) => !e.automatic).length;

  Corner corner(Side side) => side == Side.red ? red : blue;

  MatchView withRemaining(Duration remaining) => MatchView(
    id: id,
    matId: matId,
    matNumber: matNumber,
    groupNumber: groupNumber,
    status: status,
    length: length,
    pointsLimit: pointsLimit,
    remaining: remaining,
    running: running,
    endReason: endReason,
    red: red,
    blue: blue,
    timeline: timeline,
    serverTime: serverTime,
    review: review,
  );

  bool get finished => status == MatchStatus.finished;

  /// What counts now: a cancel wipes the match, so only what came after the last one.
  Iterable<TimelineEntry> get _sinceCancel {
    final last = timeline.lastIndexWhere((e) => e.action == MatchAction.cancel);
    return last < 0 ? timeline : timeline.skip(last + 1);
  }

  /// The clock was started at least once (since a cancel): only then can anyone score.
  bool get started => _sinceCancel.any((e) => e.action == MatchAction.start);

  /// What an undo would undo now: the last point (added or removed), warning,
  /// disqualification or clock adjustment in force.
  TimelineEntry? get lastUndoable => finished
      ? null
      : _sinceCancel
            .where(
              (e) =>
                  !e.undone &&
                  const {
                    MatchAction.point,
                    MatchAction.pointRemoved,
                    MatchAction.warning,
                    MatchAction.oneHandWarning,
                    MatchAction.disqualification,
                    MatchAction.clockAdjust,
                  }.contains(e.action),
            )
            .lastOrNull;

  bool get canUndo => lastUndoable != null;

  /// The rival of a disqualified fighter, else the one with more points; null on a draw.
  Side? get winner {
    if (red.disqualified) return Side.blue;
    if (blue.disqualified) return Side.red;
    if (red.points == blue.points) return null;
    return red.points > blue.points ? Side.red : Side.blue;
  }
}
