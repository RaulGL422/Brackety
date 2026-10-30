enum EventRole { club, grouper, referee }

/// An event where the signed-in account has a role.
class MyEvent {
  const MyEvent({
    required this.id,
    required this.name,
    required this.date,
    required this.roles,
    required this.maxGroupsPerMat,
    this.matId,
    this.matNumber,
  });

  factory MyEvent.fromJson(Map<String, dynamic> json) => MyEvent(
    id: json['id'] as String,
    name: json['name'] as String,
    date: DateTime.parse(json['date'] as String),
    roles: {
      for (final role in json['roles'] as List)
        EventRole.values.byName((role as String).toLowerCase()),
    },
    maxGroupsPerMat: json['maxGroupsPerMat'] as int,
    matId: json['matId'] as String?,
    matNumber: json['matNumber'] as int?,
  );

  final String id;
  final String name;
  final DateTime date;
  final Set<EventRole> roles;

  /// How many groups a helper sends to one mat at once (1 = no multigroup).
  final int maxGroupsPerMat;

  /// The referee's mat, if any.
  final String? matId;
  final int? matNumber;
}
