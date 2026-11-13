enum EventRole { club, grouper, referee }

/// An event where the signed-in account has a role.
class MyEvent {
  const MyEvent({
    required this.id,
    required this.name,
    required this.date,
    required this.roles,
    this.matId,
    this.matNumber,
    String? leagueId,
    String? leagueName,
    this.phaseNumber = 1,
  }) : leagueId = leagueId ?? id,
       leagueName = leagueName ?? name;

  factory MyEvent.fromJson(Map<String, dynamic> json) => MyEvent(
    id: json['id'] as String,
    name: json['name'] as String,
    date: DateTime.parse(json['date'] as String),
    roles: {
      for (final role in json['roles'] as List)
        EventRole.values.byName((role as String).toLowerCase()),
    },
    matId: json['matId'] as String?,
    matNumber: json['matNumber'] as int?,
    leagueId: json['leagueId'] as String?,
    leagueName: json['leagueName'] as String?,
    phaseNumber: json['phaseNumber'] as int? ?? 1,
  );

  final String id;
  final String name;
  final DateTime date;
  final Set<EventRole> roles;

  /// The referee's mat, if any.
  final String? matId;
  final int? matNumber;

  /// Each event is a phase of a league; one without league is phase 1 of its own.
  final String leagueId;
  final String leagueName;
  final int phaseNumber;
}
