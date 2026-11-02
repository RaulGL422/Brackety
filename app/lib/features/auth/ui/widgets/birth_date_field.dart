import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// Date of birth through the Material date picker, typed by default (faster than scrolling decades).
class BirthDateField extends FormField<DateTime> {
  BirthDateField({
    super.key,
    required DateTime today,
    super.validator,
    super.initialValue,
    ValueChanged<DateTime>? onChanged,
  }) : super(
         builder: (field) =>
             _BirthDateInput(field: field, today: today, onChanged: onChanged),
       );
}

class _BirthDateInput extends StatelessWidget {
  const _BirthDateInput({
    required this.field,
    required this.today,
    this.onChanged,
  });

  final FormFieldState<DateTime> field;
  final DateTime today;
  final ValueChanged<DateTime>? onChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialEntryMode: DatePickerEntryMode.input,
      initialDate: field.value,
      firstDate: DateTime(1900),
      lastDate: today,
    );
    if (picked == null) return;
    field.didChange(picked);
    onChanged?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final value = field.value;
    return InkWell(
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.registerBirthDate,
          errorText: field.errorText,
          errorMaxLines: 4,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        isEmpty: value == null,
        child: Text(value == null ? '' : DateFormat.yMd(locale).format(value)),
      ),
    );
  }
}
