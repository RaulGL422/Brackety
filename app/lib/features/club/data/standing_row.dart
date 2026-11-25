class StandingRow {
  const StandingRow({
    required this.position,
    required this.participantId,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.attendancePoints,
    required this.matchPoints,
    required this.total,
    required this.matches,
    this.categoryId,
    this.categoryName,
    this.teamNumber,
    this.wins,
    this.classificationPoints,
  });

  factory StandingRow.fromJson(Map<String, dynamic> json) => StandingRow(
    position: json['position'] as int,
    participantId: json['participantId'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    age: json['age'] as int,
    categoryId: json['categoryId'] as String?,
    categoryName: json['categoryName'] as String?,
    attendancePoints: json['attendancePoints'] as int,
    matchPoints: json['matchPoints'] as int,
    total: json['total'] as int,
    matches: json['matches'] as int,
    teamNumber: json['teamNumber'] as int?,
    wins: json['wins'] as int?,
    classificationPoints: json['classificationPoints'] as int?,
  );

  /// Equal totals share the position.
  final int position;
  final String participantId;
  final String firstName;
  final String lastName;
  final int age;
  final String? categoryId;
  final String? categoryName;
  final int attendancePoints;

  /// The participant's real team, or null.
  final int? teamNumber;
  final int matchPoints;
  final int total;
  final int matches;

  /// When the sport ranks by them (grappling, FELODA): the wins and the classification
  /// points; null otherwise (tambo ranks by [total]).
  final int? wins;
  final int? classificationPoints;
}
