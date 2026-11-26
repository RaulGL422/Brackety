import 'event_category.dart';
import 'measure_rules.dart';
import 'participant.dart';
import 'staff_member.dart';

class EventSettings {
  const EventSettings({
    required this.name,
    required this.date,
    required this.matReferees,
    required this.referees,
    this.staff = const [],
    required this.categories,
    required this.matchLength,
    required this.pointsLimit,
    required this.attendancePoints,
    this.organizations = const [],
    this.teamMatchLength = const Duration(minutes: 3),
    this.teamPointsLimit = 0,
    this.minRest = const Duration(seconds: 30),
    this.superiorityGap = 0,
    this.weightChoice,
    this.heightChoice,
    this.sportWeight = MeasureRequirement.optional,
    this.sportHeight = MeasureRequirement.optional,
    this.ownWarningReasons,
    this.sportWarningReasons = const [],
  });

  factory EventSettings.fromJson(Map<String, dynamic> json) {
    final mats = [
      for (final m in json['mats'] as List) m as Map<String, dynamic>,
    ]..sort((a, b) => (a['number'] as int).compareTo(b['number'] as int));
    final measures = json['measures'] as Map<String, dynamic>?;
    final reasons = json['warningReasons'] as Map<String, dynamic>?;
    return EventSettings(
      name: json['name'] as String,
      date: DateTime.parse(json['date'] as String),
      matReferees: [for (final m in mats) m['refereeId'] as String?],
      referees: [
        for (final r in json['referees'] as List)
          StaffMember.fromJson(r as Map<String, dynamic>),
      ],
      staff: [
        for (final s in json['staff'] as List? ?? const [])
          StaffMember.fromJson(s as Map<String, dynamic>),
      ],
      categories: [
        for (final c in json['categories'] as List)
          EventCategory.fromJson(c as Map<String, dynamic>),
      ],
      matchLength: Duration(seconds: json['matchSeconds'] as int),
      pointsLimit: json['pointsLimit'] as int,
      attendancePoints: json['attendancePoints'] as int,
      organizations: [
        for (final o in json['organizations'] as List? ?? [])
          Organization.fromJson(o as Map<String, dynamic>),
      ],
      teamMatchLength: Duration(
        seconds: json['teamMatchSeconds'] as int? ?? 180,
      ),
      teamPointsLimit: json['teamPointsLimit'] as int? ?? 0,
      minRest: Duration(seconds: json['minRestSeconds'] as int? ?? 30),
      superiorityGap:
          (json['scoring'] as Map<String, dynamic>?)?['superiorityGap']
              as int? ??
          0,
      weightChoice: MeasureRequirement.fromJson(measures?['weight']),
      heightChoice: MeasureRequirement.fromJson(measures?['height']),
      sportWeight:
          MeasureRequirement.fromJson(measures?['sportWeight']) ??
          MeasureRequirement.optional,
      sportHeight:
          MeasureRequirement.fromJson(measures?['sportHeight']) ??
          MeasureRequirement.optional,
      ownWarningReasons: switch (reasons?['own']) {
        final List<dynamic> own => [for (final r in own) r as String],
        _ => null,
      },
      sportWarningReasons: [
        for (final r in reasons?['sport'] as List? ?? const []) r as String,
      ],
    );
  }

  final String name;
  final DateTime date;

  /// One entry per mat, mat 1 first: the referee's account id, or null.
  final List<String?> matReferees;

  /// Accounts that can referee a mat in this event.
  final List<StaffMember> referees;

  /// Every helper and referee, with the person behind each account.
  final List<StaffMember> staff;
  final List<EventCategory> categories;
  final Duration matchLength;

  /// Points that end a match (0 = no limit); a disqualification gives them to the rival.
  final int pointsLimit;

  /// Points everyone in a group of this phase adds to the standings.
  final int attendancePoints;

  /// Team matches have their own length and points limit (0 = no limit).
  final Duration teamMatchLength;
  final int teamPointsLimit;

  /// The least rest of a fighter between two matches, on any mat.
  final Duration minRest;

  /// The points difference that ends a match (grappling: 15); 0 = none.
  final int superiorityGap;

  /// The clubs taking part, in the order the club entered them.
  final List<Organization> organizations;

  /// The event's own choice for weight and height; null follows the sport ([sportWeight], [sportHeight]).
  final MeasureRequirement? weightChoice;
  final MeasureRequirement? heightChoice;
  final MeasureRequirement sportWeight;
  final MeasureRequirement sportHeight;

  /// The event's own warning reasons; null follows the sport ([sportWarningReasons]).
  final List<String>? ownWarningReasons;
  final List<String> sportWarningReasons;
}

/// As the server allows (WarningReasonsRequest).
const maxWarningReasons = 20;
