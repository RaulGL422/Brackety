import 'sex.dart';

/// A club taking part in the event; [id] is null until saved.
class Organization {
  const Organization({this.id, required this.name, this.shortName});

  factory Organization.fromJson(Map<String, dynamic> json) => Organization(
    id: json['id'] as String?,
    name: json['name'] as String,
    shortName: json['shortName'] as String?,
  );

  final String? id;
  final String name;
  final String? shortName;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'shortName': shortName,
  };
}

/// From this age on the day of the event no guardian has to agree.
const adultAge = 18;

class Participant {
  const Participant({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.guardianConsent,
    required this.age,
    this.sex,
    this.heightCm,
    this.weightKg,
    this.categoryName,
    this.chosenCategoryId,
    this.organizationId,
    this.organizationName,
  });

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
    id: json['id'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    birthDate: DateTime.parse(json['birthDate'] as String),
    guardianConsent: json['guardianConsent'] as bool,
    age: json['age'] as int,
    sex: Sex.fromJson(json['sex']),
    heightCm: json['heightCm'] as int?,
    weightKg: (json['weightKg'] as num?)?.toDouble(),
    categoryName: json['categoryName'] as String?,
    chosenCategoryId: json['chosenCategoryId'] as String?,
    organizationId: json['organizationId'] as String?,
    organizationName: json['organizationName'] as String?,
  );

  final String id;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final bool guardianConsent;

  /// Age on the day of the event.
  final int age;

  /// Null only for people entered before it was asked.
  final Sex? sex;

  /// Measured for this event.
  final int? heightCm;
  final double? weightKg;

  /// Null when no category of the event covers the age.
  final String? categoryName;

  /// Set when a category was chosen for them instead of following their age.
  final String? chosenCategoryId;

  /// Their club, if the event lists clubs.
  final String? organizationId;
  final String? organizationName;

  /// A minor on the day of the event whose guardian's agreement is not ticked.
  bool get needsGuardian => age < adultAge && !guardianConsent;
}
