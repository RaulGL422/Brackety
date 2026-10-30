class CategorySummary {
  const CategorySummary({
    required this.id,
    required this.name,
    required this.participants,
    required this.grouped,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) =>
      CategorySummary(
        id: json['id'] as String,
        name: json['name'] as String,
        participants: json['participants'] as int,
        grouped: json['grouped'] as int,
      );

  final String id;
  final String name;
  final int participants;
  final int grouped;
}

class CategoryParticipant {
  const CategoryParticipant({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.age,
    this.heightCm,
    this.groupNumber,
    this.matNumber,
  });

  factory CategoryParticipant.fromJson(Map<String, dynamic> json) =>
      CategoryParticipant(
        id: json['id'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        age: json['age'] as int,
        heightCm: json['heightCm'] as int?,
        groupNumber: json['groupNumber'] as int?,
        matNumber: json['matNumber'] as int?,
      );

  final String id;
  final String firstName;
  final String lastName;
  final int age;
  final int? heightCm;

  /// Set once the participant competes in a group (not as a ghost).
  final int? groupNumber;
  final int? matNumber;

  bool get isGrouped => groupNumber != null;

  String get fullName => '$firstName $lastName';
}

class CreatedGroups {
  const CreatedGroups({required this.matNumber, required this.groupNumbers});

  factory CreatedGroups.fromJson(Map<String, dynamic> json) => CreatedGroups(
    matNumber: json['matNumber'] as int,
    groupNumbers: [for (final n in json['groupNumbers'] as List) n as int],
  );

  final int matNumber;
  final List<int> groupNumbers;
}
