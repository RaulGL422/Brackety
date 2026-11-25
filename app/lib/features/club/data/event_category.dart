/// An age band of the event; [teamSize] is null when it competes individually. [matchLength]:
/// null when its matches last as the event says (grappling: U13, U15 and veterans fight 4 min).
/// Group sizes and return leg: null in a category not saved yet (the server makes groups of 4, one
/// leg) and sent back as they came, so editing a category keeps them.
class EventCategory {
  const EventCategory({
    this.id,
    required this.name,
    required this.minAge,
    required this.maxAge,
    this.teamSize,
    this.minGroupSize,
    this.maxGroupSize,
    this.returnLeg,
    this.matchLength,
  });

  factory EventCategory.fromJson(Map<String, dynamic> json) => EventCategory(
    id: json['id'] as String,
    name: json['name'] as String,
    minAge: json['minAge'] as int,
    maxAge: json['maxAge'] as int,
    teamSize: json['format'] == 'TEAM' ? json['teamSize'] as int? : null,
    minGroupSize: json['minGroupSize'] as int?,
    maxGroupSize: json['maxGroupSize'] as int?,
    returnLeg: json['returnLeg'] as bool?,
    matchLength: switch (json['matchSeconds']) {
      final int seconds => Duration(seconds: seconds),
      _ => null,
    },
  );

  /// Null for a category not saved yet.
  final String? id;
  final String name;
  final int minAge;
  final int maxAge;
  final int? teamSize;

  /// Participants or teams per group, wildcards included.
  final int? minGroupSize;
  final int? maxGroupSize;

  /// Everyone in a group fights everyone twice.
  final bool? returnLeg;
  final Duration? matchLength;

  bool get isTeam => teamSize != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'minAge': minAge,
    'maxAge': maxAge,
    'format': isTeam ? 'TEAM' : 'INDIVIDUAL',
    'teamSize': teamSize,
    'minGroupSize': minGroupSize,
    'maxGroupSize': maxGroupSize,
    'returnLeg': returnLeg,
    'matchSeconds': matchLength?.inSeconds,
  };
}
