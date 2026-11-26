/// Required for new people; null only for those entered before it was asked (F1).
enum Sex {
  female,
  male;

  String toJson() => name.toUpperCase();

  static Sex? fromJson(Object? json) => switch (json) {
    'FEMALE' => Sex.female,
    'MALE' => Sex.male,
    _ => null,
  };
}
