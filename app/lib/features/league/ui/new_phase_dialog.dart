import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../events/state/events_providers.dart';
import '../data/league_models.dart';
import '../data/league_repository.dart';
import '../state/league_providers.dart';
import 'league_tab.dart';

/// Creates the next phase from [eventId]'s settings and opens its panel.
Future<void> showNewPhaseDialog(
  BuildContext context,
  String eventId,
  League league,
) => showDialog<void>(
  context: context,
  builder: (_) => _NewPhaseDialog(eventId: eventId, league: league),
);

class _NewPhaseDialog extends ConsumerStatefulWidget {
  const _NewPhaseDialog({required this.eventId, required this.league});

  final String eventId;
  final League league;

  @override
  ConsumerState<_NewPhaseDialog> createState() => _NewPhaseDialogState();
}

class _NewPhaseDialogState extends ConsumerState<_NewPhaseDialog> {
  final _form = GlobalKey<FormState>();
  late final _number = widget.league.phases.last.number + 1;
  late final _name = TextEditingController();
  final _attendance = TextEditingController(text: '10');
  late DateTime _date = _fourWeeksAfter(widget.league.phases.last.date);
  late var _discipline = Discipline.values.firstWhere(
    widget.league.availableDisciplines.contains,
    orElse: () => Discipline.tambo,
  );

  // By calendar day, not by hours: adding 28 × 24 h lands a day early across a DST change.
  static DateTime _fourWeeksAfter(DateTime d) =>
      DateTime(d.year, d.month, d.day + 28);
  var _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_name.text.isEmpty) {
      _name.text = AppLocalizations.of(context)
          .leaguePhaseDefaultName(widget.league.name, _number);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _attendance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return AlertDialog(
      actionsOverflowDirection: VerticalDirection.up,
      actionsOverflowButtonSpacing: 8,
      title: Text(l10n.leagueNewPhaseTitle(_number)),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.leagueNewPhaseHint),
                const SizedBox(height: AppSpacing.m),
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(labelText: l10n.leaguePhaseName),
                  maxLength: 120,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: AppSpacing.s),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.settingsDate,
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(DateFormat.yMMMMd(locale).format(_date)),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                DropdownButtonFormField<Discipline>(
                  initialValue: _discipline,
                  decoration: InputDecoration(labelText: l10n.leagueDiscipline),
                  items: [
                    for (final d in Discipline.values)
                      DropdownMenuItem(
                        value: d,
                        enabled: widget.league.availableDisciplines.contains(d),
                        child: Text(
                          widget.league.availableDisciplines.contains(d)
                              ? disciplineName(l10n, d)
                              : l10n.disciplineSoon(disciplineName(l10n, d)),
                        ),
                      ),
                  ],
                  onChanged: (d) => setState(() => _discipline = d!),
                ),
                const SizedBox(height: AppSpacing.m),
                TextFormField(
                  controller: _attendance,
                  decoration: InputDecoration(
                    labelText: l10n.leagueAttendancePoints,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final points = int.tryParse(v?.trim() ?? '');
                    return points == null || points < 0 || points > 100
                        ? l10n.leagueAttendanceInvalid
                        : null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _create,
          child: Text(l10n.leagueNewPhaseCreate),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_date.year - 1),
      lastDate: DateTime(_date.year + 2),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _create() async {
    if (!_form.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    final router = GoRouter.of(context);
    setState(() => _saving = true);
    try {
      final phase = await ref
          .read(leagueRepositoryProvider)
          .createPhase(
            widget.eventId,
            name: _name.text.trim(),
            date: _date,
            discipline: _discipline,
            attendancePoints: int.parse(_attendance.text.trim()),
          );
      ref
        ..invalidate(myEventsProvider)
        ..invalidate(leagueProvider(widget.eventId));
      if (mounted) Navigator.pop(context);
      toasts.show(
        l10n.leagueNewPhaseDone(phase.number),
        kind: ToastKind.success,
      );
      router.go('/events/${phase.eventId}/club');
    } on DioException catch (e) {
      if (mounted) setState(() => _saving = false);
      toasts.show(
        e.response?.statusCode == 400 ? l10n.saveInvalid : l10n.saveError,
        kind: ToastKind.error,
      );
    }
  }
}
