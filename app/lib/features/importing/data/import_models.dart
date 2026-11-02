import 'package:intl/intl.dart';

final _day = DateFormat('yyyy-MM-dd');

/// One participant of a list, as read and then edited by the club. The server checks it.
class ImportRow {
  const ImportRow({
    this.firstName,
    this.lastName,
    this.birthDate,
    this.birthDateText,
    this.heightCm,
    this.categoryText,
    this.categoryId,
    this.unsure = const [],
  });

  factory ImportRow.fromJson(Map<String, dynamic> json) => ImportRow(
    firstName: json['firstName'] as String?,
    lastName: json['lastName'] as String?,
    birthDate: json['birthDate'] == null
        ? null
        : DateTime.parse(json['birthDate'] as String),
    birthDateText: json['birthDateText'] as String?,
    heightCm: json['heightCm'] as int?,
    categoryText: json['categoryText'] as String?,
    categoryId: json['categoryId'] as String?,
    unsure: [for (final u in json['unsure'] as List? ?? []) u as String],
  );

  final String? firstName;
  final String? lastName;
  final DateTime? birthDate;

  /// The date as written, kept when it is not a real date.
  final String? birthDateText;
  final int? heightCm;

  /// The category as written in the list.
  final String? categoryText;

  /// A category the club chose; null follows the age.
  final String? categoryId;

  /// Fields that could not be read with certainty.
  final List<String> unsure;

  String get fullName => [firstName, lastName].whereType<String>().join(' ');

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'birthDate': birthDate == null ? null : _day.format(birthDate!),
    'birthDateText': birthDateText,
    'heightCm': heightCm,
    'categoryText': categoryText,
    'categoryId': categoryId,
    'unsure': unsure,
  };

  /// Edited by hand: what was doubtful has been looked at.
  ImportRow edited({
    required String firstName,
    required String lastName,
    required DateTime? birthDate,
    required int? heightCm,
  }) => ImportRow(
    firstName: firstName,
    lastName: lastName,
    birthDate: birthDate,
    birthDateText: birthDate == null ? birthDateText : null,
    heightCm: heightCm,
    categoryText: categoryText,
    categoryId: categoryId,
  );

  /// The club settles the category: [id] wins over the written one; null goes by age.
  ImportRow withCategory(String? id) => ImportRow(
    firstName: firstName,
    lastName: lastName,
    birthDate: birthDate,
    birthDateText: birthDateText,
    heightCm: heightCm,
    categoryId: id,
    unsure: [
      for (final u in unsure)
        if (u != 'category') u,
    ],
  );
}

enum IssueCode {
  missing,
  tooLong,
  invalidDate,
  futureDate,
  heightOutOfRange,
  noCategory,
  unknownCategory,
  categoryMismatch,
  duplicateInList,
  alreadyRegistered,
  unsure,
}

class RowIssue {
  const RowIssue({required this.field, required this.code, this.detail});

  factory RowIssue.fromJson(Map<String, dynamic> json) => RowIssue(
    field: json['field'] as String,
    code: switch (json['code'] as String) {
      'MISSING' => IssueCode.missing,
      'TOO_LONG' => IssueCode.tooLong,
      'INVALID_DATE' => IssueCode.invalidDate,
      'FUTURE_DATE' => IssueCode.futureDate,
      'HEIGHT_OUT_OF_RANGE' => IssueCode.heightOutOfRange,
      'NO_CATEGORY' => IssueCode.noCategory,
      'UNKNOWN_CATEGORY' => IssueCode.unknownCategory,
      'CATEGORY_MISMATCH' => IssueCode.categoryMismatch,
      'DUPLICATE_IN_LIST' => IssueCode.duplicateInList,
      'ALREADY_REGISTERED' => IssueCode.alreadyRegistered,
      _ => IssueCode.unsure,
    },
    detail: json['detail'] as String?,
  );

  /// firstName, lastName, birthDate, heightCm or category.
  final String field;
  final IssueCode code;
  final String? detail;
}

/// A row with what the server makes of it.
class CheckedRow {
  const CheckedRow({
    required this.row,
    this.errors = const [],
    this.warnings = const [],
    this.age,
    this.categoryName,
    this.indicatedCategoryId,
    this.indicatedCategoryName,
    this.ageCategoryId,
    this.ageCategoryName,
  });

  factory CheckedRow.fromJson(Map<String, dynamic> json) => CheckedRow(
    row: ImportRow.fromJson(json['row'] as Map<String, dynamic>),
    age: json['age'] as int?,
    categoryName: json['categoryName'] as String?,
    indicatedCategoryId: json['indicatedCategoryId'] as String?,
    indicatedCategoryName: json['indicatedCategoryName'] as String?,
    ageCategoryId: json['ageCategoryId'] as String?,
    ageCategoryName: json['ageCategoryName'] as String?,
    errors: [
      for (final e in json['errors'] as List)
        RowIssue.fromJson(e as Map<String, dynamic>),
    ],
    warnings: [
      for (final w in json['warnings'] as List)
        RowIssue.fromJson(w as Map<String, dynamic>),
    ],
  );

  final ImportRow row;
  final int? age;

  /// Where they would compete, once nothing is wrong with the category.
  final String? categoryName;

  /// With a category mismatch: the written category and the one by age, the two choices.
  final String? indicatedCategoryId;
  final String? indicatedCategoryName;
  final String? ageCategoryId;
  final String? ageCategoryName;
  final List<RowIssue> errors;
  final List<RowIssue> warnings;

  bool get isValid => errors.isEmpty;
}
