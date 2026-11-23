import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../data/league_models.dart';

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
    required this.sports,
    required this.onChanged,
    this.validator,
  });

  /// A [Sport.code].
  final String? value;
  final List<Sport> sports;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    return DropdownButtonFormField<String>(
      initialValue: value,
      // Sized by the form, not by the longest sport: it overflowed a phone.
      isExpanded: true,
      decoration: InputDecoration(labelText: l10n.leagueDiscipline),
      items: [
        for (final s in sports)
          DropdownMenuItem(
            value: s.code,
            enabled: s.available,
            child: Text(
              s.available
                  ? s.name(language)
                  : l10n.disciplineSoon(s.name(language)),
            ),
          ),
      ],
      validator: validator,
      onChanged: (d) => onChanged(d!),
    );
  }
}
