import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/sex.dart';

/// Required: the club picks one. Starts empty for people entered before it was asked.
class SexField extends FormField<Sex> {
  SexField({
    super.key,
    super.initialValue,
    required String requiredText,
    required ValueChanged<Sex> onChanged,
  }) : super(
         validator: (v) => v == null ? requiredText : null,
         builder: (state) {
           final l10n = AppLocalizations.of(state.context);
           return InputDecorator(
             decoration: InputDecoration(
               labelText: l10n.sexLabel,
               errorText: state.errorText,
               border: InputBorder.none,
             ),
             child: SegmentedButton<Sex>(
               emptySelectionAllowed: true,
               segments: [
                 ButtonSegment(value: Sex.female, label: Text(l10n.sexFemale)),
                 ButtonSegment(value: Sex.male, label: Text(l10n.sexMale)),
               ],
               selected: {?state.value},
               onSelectionChanged: (selected) {
                 if (selected.isEmpty) return;
                 state.didChange(selected.first);
                 onChanged(selected.first);
               },
             ),
           );
         },
       );
}

/// Optional height in cm.
class HeightField extends StatelessWidget {
  const HeightField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: l10n.heightOptional),
      keyboardType: TextInputType.number,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        final cm = int.tryParse(v.trim());
        return cm == null || cm < 50 || cm > 250 ? l10n.heightInvalid : null;
      },
    );
  }
}

/// Optional weight in kg, written with a comma or a point ("32,5").
class WeightField extends StatelessWidget {
  const WeightField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: l10n.weightOptional),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        final text = v.trim().replaceAll(',', '.');
        final kg = double.tryParse(text);
        final decimals = text.contains('.') ? text.split('.').last.length : 0;
        return kg == null || kg < 10 || kg > 250 || decimals > 1
            ? l10n.weightInvalid
            : null;
      },
    );
  }
}

/// What [WeightField] holds, or null when empty.
double? parseWeight(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

/// "32,5 kg" in Spanish, "32.5 kg" in English.
String weightText(AppLocalizations l10n, String locale, double kg) =>
    l10n.weightKg(NumberFormat('0.#', locale).format(kg));

String sexText(AppLocalizations l10n, Sex? sex) => switch (sex) {
  Sex.female => l10n.sexFemale,
  Sex.male => l10n.sexMale,
  null => l10n.sexUnknown,
};
