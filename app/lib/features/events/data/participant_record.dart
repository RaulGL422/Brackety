import '../../match/data/mat_board.dart';
import 'standing_row.dart';

/// One participant's day: their standing row and every match they fight (with their team or as a
/// ghost too), as the club opens it.
class ParticipantRecord {
  const ParticipantRecord({required this.standing, required this.matches});

  factory ParticipantRecord.fromJson(Map<String, dynamic> json) =>
      ParticipantRecord(
        standing: StandingRow.fromJson(
          json['standing'] as Map<String, dynamic>,
        ),
        matches: [
          for (final m in json['matches'] as List)
            RecordMatch.fromJson(m as Map<String, dynamic>),
        ],
      );

  final StandingRow standing;
  final List<RecordMatch> matches;
}

enum IncidentKind { warning, oneHandWarning, disqualification, overtimePoint }

/// A warning, one-hand warning or disqualification of a match: why, when on its clock and who.
/// [gaveRivalPoint]: a second warning that gave the rival a point.
class Incident {
  const Incident({
    required this.kind,
    required this.reason,
    required this.clock,
    this.by,
    this.gaveRivalPoint = false,
  });

  factory Incident.fromJson(Map<String, dynamic> json) => Incident(
    kind: switch (json['kind']) {
      'ONE_HAND_WARNING' => IncidentKind.oneHandWarning,
      'DISQUALIFICATION' => IncidentKind.disqualification,
      'OVERTIME_POINT' => IncidentKind.overtimePoint,
      _ => IncidentKind.warning,
    },
    reason: json['reason'] as String? ?? '',
    clock: Duration(milliseconds: json['clockMs'] as int),
    by: json['by'] as String?,
    gaveRivalPoint: json['gaveRivalPoint'] as bool? ?? false,
  );

  final IncidentKind kind;
  final String reason;
  final Duration clock;
  final String? by;
  final bool gaveRivalPoint;

  bool get isWarning => kind != IncidentKind.disqualification;
}

/// One person across the league: each phase they entered, with its matches.
class LeagueRecord {
  const LeagueRecord(this.phases);

  factory LeagueRecord.fromJson(Map<String, dynamic> json) => LeagueRecord([
    for (final p in json['phases'] as List)
      (
        number: (p as Map<String, dynamic>)['number'] as int,
        name: p['name'] as String,
        matches: [
          for (final m in p['matches'] as List)
            RecordMatch.fromJson(m as Map<String, dynamic>),
        ],
      ),
  ]);

  final List<({int number, String name, List<RecordMatch> matches})> phases;
}

/// [red]: they fight in red. [asGhost]: they (or their team) only fill the group in.
class RecordMatch {
  const RecordMatch({
    required this.matchId,
    required this.matNumber,
    required this.groupNumber,
    required this.status,
    required this.red,
    required this.asGhost,
    this.team,
    required this.rival,
    required this.points,
    required this.rivalPoints,
    required this.warnings,
    required this.oneHandWarnings,
    required this.disqualified,
    required this.rivalDisqualified,
    this.endReason,
    this.incidents = const [],
  });

  factory RecordMatch.fromJson(Map<String, dynamic> json) => RecordMatch(
    matchId: json['matchId'] as String,
    matNumber: json['matNumber'] as int?,
    groupNumber: json['groupNumber'] as int,
    status: switch (json['status']) {
      'IN_PROGRESS' => MatchStatus.inProgress,
      'FINISHED' => MatchStatus.finished,
      _ => MatchStatus.pending,
    },
    red: json['side'] == 'RED',
    asGhost: json['asGhost'] as bool,
    team: json['team'] as int?,
    rival: json['rival'] as String,
    points: json['points'] as int,
    rivalPoints: json['rivalPoints'] as int,
    warnings: json['warnings'] as int,
    oneHandWarnings: json['oneHandWarnings'] as int,
    disqualified: json['disqualified'] as bool,
    rivalDisqualified: json['rivalDisqualified'] as bool,
    endReason: json['endReason'] as String?,
    incidents: [
      for (final i in json['incidents'] as List? ?? const [])
        Incident.fromJson(i as Map<String, dynamic>),
    ],
  );

  /// Their warnings and disqualification that stand, in order.
  final List<Incident> incidents;

  final String matchId;

  /// Null for a team match not started yet.
  final int? matNumber;
  final int groupNumber;
  final MatchStatus status;
  final bool red;
  final bool asGhost;
  final int? team;
  final String rival;
  final int points;
  final int rivalPoints;
  final int warnings;
  final int oneHandWarnings;
  final bool disqualified;
  final bool rivalDisqualified;
  final String? endReason;
}
