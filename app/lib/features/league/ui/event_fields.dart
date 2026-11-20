import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/league_models.dart';
import 'league_tab.dart';

/// The event's day, picked from a calendar: up to a year back and two ahead.
class DateField extends StatelessWidget {
  const DateField({super.key, required this.date, required this.onChanged});

  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(date.year - 1),
          lastDate: DateTime(date.year + 2),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context).settingsDate,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(DateFormat.yMMMMd(locale).format(date)),
      ),
    );
  }
}

/// The sport: those without a scoreboard yet show, but cannot be picked. Null until picked,
/// and then [validator] decides.
class SportField extends StatelessWidget {
  const SportField({
    super.key,
    required this.value,
    required this.available,
    required this.onChanged,
    this.validator,
  });

  final Discipline? value;
  final Set<Discipline> available;
  final ValueChanged<Discipline> onChanged;
  final FormFieldValidator<Discipline>? validator;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<Discipline>(
      initialValue: value,
      // Sized by the form, not by the longest sport: it overflowed a phone.
      isExpanded: true,
      decoration: InputDecoration(labelText: l10n.leagueDiscipline),
      items: [
        for (final d in Discipline.values)
          DropdownMenuItem(
            value: d,
            enabled: available.contains(d),
            child: Text(
              available.contains(d)
                  ? disciplineName(l10n, d)
                  : l10n.disciplineSoon(disciplineName(l10n, d)),
            ),
          ),
      ],
      validator: validator,
      onChanged: (d) => onChanged(d!),
    );
  }
}
