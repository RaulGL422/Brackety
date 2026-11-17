/// Whether an event asks for a measure of each participant (F2-1). Required: nobody goes into a group or team
/// without it. Optional: the grouping screens say who lacks it. Off: not asked.
enum MeasureRequirement {
  off,
  optional,
  required;

  String toJson() => name.toUpperCase();

  static MeasureRequirement? fromJson(Object? json) => switch (json) {
    'OFF' => off,
    'OPTIONAL' => optional,
    'REQUIRED' => required,
    _ => null,
  };
}

/// What the event asks: its own choice or its sport's.
class MeasureRules {
  const MeasureRules({
    this.weight = MeasureRequirement.optional,
    this.height = MeasureRequirement.optional,
  });

  final MeasureRequirement weight;
  final MeasureRequirement height;

  /// Missing a required measure: they cannot go into a group or team yet.
  bool blocks({required double? weightKg, required int? heightCm}) =>
      (weight == MeasureRequirement.required && weightKg == null) ||
      (height == MeasureRequirement.required && heightCm == null);
}
