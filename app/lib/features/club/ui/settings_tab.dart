import 'dart:async';

import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/async_view.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/data/api_error.dart';
import '../../auth/ui/widgets/confirm_dialog.dart';
import '../../events/data/my_event.dart';
import '../../events/state/events_providers.dart';
import '../../league/state/league_providers.dart';
import '../../rulebook/rulebook_ui.dart';
import '../../staff/data/staff_repository.dart';
import '../../staff/ui/qr_access.dart';
import '../../staff/ui/qr_access_section.dart';
import '../../staff/ui/staff_section.dart';
import '../data/club_models.dart';
import '../data/club_repository.dart';
import '../state/club_providers.dart';
import 'categories_editor.dart';
import 'club_panel_screen.dart';
import 'measures_editor.dart';
import 'organizations_editor.dart';
import 'warning_reasons_editor.dart';

const maxMats = 20;

/// "3:00" for 3 minutes.
String formatMatchLength(Duration length) =>
    '${length.inMinutes}:${(length.inSeconds % 60).toString().padLeft(2, '0')}';

/// "3:00", "3" (minutes) or "2:30" between 0:30 and 20:00 (the server's range), else null.
Duration? parseMatchLength(String text) {
  final match = RegExp(r'^\s*(\d{1,2})(?::(\d{2}))?\s*$').firstMatch(text);
  if (match == null) return null;
  final seconds = int.parse(match[2] ?? '0');
  if (seconds > 59) return null;
  final length = Duration(minutes: int.parse(match[1]!), seconds: seconds);
  return length < const Duration(seconds: 30) ||
          length > const Duration(minutes: 20)
      ? null
      : length;
}

/// Empty or 0: no limit (returns 0); else up to [max], or null if invalid.
int? parsePointsLimit(String text, {int max = 99}) {
  if (text.trim().isEmpty) return 0;
  final value = int.tryParse(text.trim());
  return value == null || value < 0 || value > max ? null : value;
}

/// Seconds, 0 to 600.
Duration? parseMinRest(String text) {
  final value = int.tryParse(text.trim());
  return value == null || value < 0 || value > 600
      ? null
      : Duration(seconds: value);
}

int? parseAttendancePoints(String text) {
  final value = int.tryParse(text.trim());
  return value == null || value < 0 || value > 100 ? null : value;
}

/// Event name and date, match length, points limit, superiority gap and attendance points, mats with their referee, and the
/// categories.
/// Every change saves on its own; a refused one goes back to what the server has.
class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = eventSettingsProvider(eventId);
    return AsyncView(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      data: (settings) => _SettingsForm(eventId: eventId, initial: settings),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({required this.eventId, required this.initial});

  final String eventId;
  final EventSettings initial;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  late var _saved = widget.initial;
  late final _name = TextEditingController(text: _saved.name);
  late var _date = _saved.date;
  late var _matReferees = [..._saved.matReferees];
  late final _length = TextEditingController(
    text: formatMatchLength(_saved.matchLength),
  );
  late final _limit = TextEditingController(
    text: _limitText(_saved.pointsLimit),
  );
  late final _teamLength = TextEditingController(
    text: formatMatchLength(_saved.teamMatchLength),
  );
  late final _teamLimit = TextEditingController(
    text: _limitText(_saved.teamPointsLimit),
  );
  late final _gap = TextEditingController(
    text: _limitText(_saved.superiorityGap),
  );
  late final _minRest = TextEditingController(
    text: '${_saved.minRest.inSeconds}',
  );
  late final _attendance = TextEditingController(
    text: '${_saved.attendancePoints}',
  );
  Timer? _nameTyping;
  var _saving = false;
  var _changedWhileSaving = false;

  @override
  void dispose() {
    _nameTyping?.cancel();
    _name.dispose();
    _length.dispose();
    _limit.dispose();
    _teamLength.dispose();
    _teamLimit.dispose();
    _gap.dispose();
    _minRest.dispose();
    _attendance.dispose();
    super.dispose();
  }

  // A QR access for a mat puts its referee there on the server: show it, unless a save is on its way.
  @override
  void didUpdateWidget(covariant _SettingsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final referees = widget.initial.matReferees;
    if (!_saving && !listEquals(referees, oldWidget.initial.matReferees)) {
      _matReferees = [...referees];
    }
  }

  Widget _matReferee(EventSettings settings, int i, String? refereeId) {
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<String?>(
      // A new key when the value changes, so a refused change shows the saved referee again.
      key: ValueKey('$i:$refereeId'),
      initialValue: refereeId,
      // A person's name next to the sign-in can be long: it is cut, never overflows a phone.
      isExpanded: true,
      decoration: InputDecoration(
        labelText: '${l10n.matTitle(i + 1)} · ${l10n.settingsReferee}',
      ),
      items: [
        DropdownMenuItem(child: Text(l10n.matNoReferee)),
        for (final r in settings.referees)
          DropdownMenuItem(
            value: r.id,
            child: Text(r.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (id) => _change(() => _matReferees[i] = id),
    );
  }

  void _change(VoidCallback update) {
    setState(update);
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final text = Theme.of(context).textTheme;
    final settings = widget.initial;
    return Form(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          TextFormField(
            controller: _name,
            decoration: InputDecoration(labelText: l10n.settingsName),
            maxLength: 120,
            validator: (v) =>
                v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
            onChanged: (_) => _typed(),
            onFieldSubmitted: (_) => _save(),
          ),
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
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.settingsMatchRules, style: text.titleMedium),
          const SizedBox(height: AppSpacing.s),
          TextFormField(
            controller: _length,
            decoration: InputDecoration(
              labelText: l10n.settingsMatchLength,
              helperText: l10n.settingsMatchLengthHint,
              helperMaxLines: 3,
            ),
            keyboardType: TextInputType.datetime,
            validator: (v) => parseMatchLength(v ?? '') == null
                ? l10n.settingsMatchLengthInvalid
                : null,
            onChanged: (_) => _typed(),
            onFieldSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.m),
          TextFormField(
            controller: _limit,
            decoration: InputDecoration(
              labelText: l10n.settingsPointsLimit,
              helperText: l10n.settingsPointsLimitHint,
              helperMaxLines: 3,
            ),
            keyboardType: TextInputType.number,
            validator: (v) => parsePointsLimit(v ?? '') == null
                ? l10n.settingsPointsLimitInvalid
                : null,
            onChanged: (_) => _typed(),
            onFieldSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.m),
          TextFormField(
            controller: _teamLength,
            decoration: InputDecoration(
              labelText: l10n.settingsTeamMatchLength,
              helperText: l10n.settingsMatchLengthHint,
              helperMaxLines: 3,
            ),
            keyboardType: TextInputType.datetime,
            validator: (v) => parseMatchLength(v ?? '') == null
                ? l10n.settingsMatchLengthInvalid
                : null,
            onChanged: (_) => _typed(),
            onFieldSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.m),
          TextFormField(
            controller: _teamLimit,
            decoration: InputDecoration(
              labelText: l10n.settingsTeamPointsLimit,
              helperText: l10n.settingsTeamPointsLimitHint,
              helperMaxLines: 3,
            ),
            keyboardType: TextInputType.number,
            validator: (v) => parsePointsLimit(v ?? '') == null
                ? l10n.settingsPointsLimitInvalid
                : null,
            onChanged: (_) => _typed(),
            onFieldSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.m),
          TextFormField(
            controller: _gap,
            decoration: InputDecoration(
              labelText: l10n.settingsSuperiorityGap,
              helperText: l10n.settingsSuperiorityGapHint,
              helperMaxLines: 3,
            ),
            keyboardType: TextInputType.number,
            validator: (v) => parsePointsLimit(v ?? '', max: 100) == null
                ? l10n.settingsSuperiorityGapInvalid
                : null,
            onChanged: (_) => _typed(),
            onFieldSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.m),
          TextFormField(
            controller: _minRest,
            decoration: InputDecoration(
              labelText: l10n.settingsMinRest,
              helperText: l10n.settingsMinRestHint,
              helperMaxLines: 3,
            ),
            keyboardType: TextInputType.number,
            validator: (v) => parseMinRest(v ?? '') == null
                ? l10n.settingsMinRestInvalid
                : null,
            onChanged: (_) => _typed(),
            onFieldSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.m),
          TextFormField(
            controller: _attendance,
            decoration: InputDecoration(
              labelText: l10n.leagueAttendancePoints,
              helperText: l10n.settingsAttendanceHint,
              helperMaxLines: 3,
            ),
            keyboardType: TextInputType.number,
            validator: (v) => parseAttendancePoints(v ?? '') == null
                ? l10n.leagueAttendanceInvalid
                : null,
            onChanged: (_) => _typed(),
            onFieldSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.clubMats, style: text.titleMedium),
          for (final (i, refereeId) in _matReferees.indexed)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s),
              child: Row(
                children: [
                  Expanded(child: _matReferee(settings, i, refereeId)),
                  // A referee without an account of their own: a QR for this mat.
                  QrAccessButton(
                    eventId: widget.eventId,
                    role: StaffRole.referee,
                    mat: i + 1,
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.s),
          Wrap(
            spacing: AppSpacing.s,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.settingsAddMat),
                onPressed: _matReferees.length >= maxMats
                    ? null
                    : () => _change(() => _matReferees.add(null)),
              ),
              TextButton.icon(
                icon: const Icon(Icons.remove),
                label: Text(l10n.settingsRemoveMat),
                onPressed: _matReferees.length <= 1 ? null : _removeLastMat,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.staffTitle, style: text.titleMedium),
          Text(l10n.staffHint, style: text.bodySmall),
          for (final member in settings.staff)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _StaffNameField(
                    key: ValueKey(member.id),
                    eventId: widget.eventId,
                    member: member,
                  ),
                ),
                StaffPermissionsButton(eventId: widget.eventId, member: member),
                StaffRemoveButton(eventId: widget.eventId, member: member),
              ],
            ),
          const SizedBox(height: AppSpacing.s),
          StaffInvitations(eventId: widget.eventId),
          const SizedBox(height: AppSpacing.xl),
          QrAccessSection(
            eventId: widget.eventId,
            matReferees: _matReferees,
            hasGrouper: settings.staff.any(
              (m) => m.permissions.contains(EventPermission.groups),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.measuresTitle, style: text.titleMedium),
          MeasuresEditor(eventId: widget.eventId, settings: settings),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.warningReasonsTitle, style: text.titleMedium),
          WarningReasonsEditor(eventId: widget.eventId, settings: settings),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.categoriesTitle, style: text.titleMedium),
          CategoriesEditor(
            eventId: widget.eventId,
            categories: settings.categories,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.organizationsTitle, style: text.titleMedium),
          OrganizationsEditor(
            eventId: widget.eventId,
            organizations: settings.organizations,
          ),
          const SizedBox(height: AppSpacing.xl),
          RulebookSection(eventId: widget.eventId),
        ],
      ),
    );
  }

  Future<void> _removeLastMat() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmAction(
      context,
      body: l10n.settingsRemoveMatConfirm(_matReferees.length),
      confirmLabel: l10n.settingsRemoveMat,
      destructive: true,
    );
    if (confirmed && mounted) _change(() => _matReferees.removeLast());
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_date.year - 1),
      lastDate: DateTime(_date.year + 2),
    );
    if (picked != null && picked != _date) _change(() => _date = picked);
  }

  // Saves once the club stops typing, not on every key.
  void _typed() {
    _nameTyping?.cancel();
    _nameTyping = Timer(const Duration(milliseconds: 800), _save);
  }

  /// One save at a time; changes made meanwhile go in the next one.
  Future<void> _save() async {
    _nameTyping?.cancel();
    final length = parseMatchLength(_length.text);
    final limit = parsePointsLimit(_limit.text);
    final attendance = parseAttendancePoints(_attendance.text);
    final teamLength = parseMatchLength(_teamLength.text);
    final teamLimit = parsePointsLimit(_teamLimit.text);
    final gap = parsePointsLimit(_gap.text, max: 100);
    final minRest = parseMinRest(_minRest.text);
    if (_name.text.trim().isEmpty ||
        length == null ||
        limit == null ||
        attendance == null ||
        teamLength == null ||
        teamLimit == null ||
        gap == null ||
        minRest == null) {
      return;
    }
    final rulesChanged =
        length != _saved.matchLength ||
        limit != _saved.pointsLimit ||
        teamLength != _saved.teamMatchLength ||
        teamLimit != _saved.teamPointsLimit ||
        gap != _saved.superiorityGap;
    if (_saving) {
      _changedWhileSaving = true;
      return;
    }
    _saving = true;
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    try {
      do {
        _changedWhileSaving = false;
        _saved = await ref
            .read(clubRepositoryProvider)
            .saveSettings(
              widget.eventId,
              name: _name.text.trim(),
              date: _date,
              matReferees: [..._matReferees],
              matchLength: length,
              pointsLimit: limit,
              attendancePoints: attendance,
              teamMatchLength: teamLength,
              teamPointsLimit: teamLimit,
              minRest: minRest,
              superiorityGap: gap,
            );
      } while (_changedWhileSaving && mounted);
      ref
        ..invalidate(eventSettingsProvider(widget.eventId))
        ..invalidate(leagueStandingsProvider(widget.eventId))
        ..invalidate(myEventsProvider)
        ..invalidate(matsOverviewProvider(widget.eventId))
        ..invalidate(participantsProvider(widget.eventId));
      toasts.show(
        l10n.saved,
        kind: ToastKind.success,
        duration: const Duration(seconds: 1),
      );
    } on DioException catch (e) {
      toasts.show(switch (ApiError.from(e).code) {
        'MAT_HAS_MATCHES' => l10n.settingsMatNeedsReferee,
        'MAT_HAS_GROUPS' => l10n.settingsMatHasGroups,
        _ when rulesChanged && e.response?.statusCode == 409 =>
          l10n.settingsMatchRulesConflict,
        _ => saveErrorMessage(l10n, e),
      }, kind: ToastKind.error);
      if (mounted) _showSaved();
    } finally {
      _saving = false;
    }
  }

  void _showSaved() => setState(() {
    _name.text = _saved.name;
    _date = _saved.date;
    _matReferees = [..._saved.matReferees];
    _length.text = formatMatchLength(_saved.matchLength);
    _limit.text = _limitText(_saved.pointsLimit);
    _teamLength.text = formatMatchLength(_saved.teamMatchLength);
    _teamLimit.text = _limitText(_saved.teamPointsLimit);
    _gap.text = _limitText(_saved.superiorityGap);
    _minRest.text = '${_saved.minRest.inSeconds}';
    _attendance.text = '${_saved.attendancePoints}';
  });
}

// No limit is an empty field.
String _limitText(int limit) => limit == 0 ? '' : '$limit';

/// The person behind one staff account; saved once the club stops typing, like the event's name.
class _StaffNameField extends ConsumerStatefulWidget {
  const _StaffNameField({
    super.key,
    required this.eventId,
    required this.member,
  });

  final String eventId;
  final StaffMember member;

  @override
  ConsumerState<_StaffNameField> createState() => _StaffNameFieldState();
}

class _StaffNameFieldState extends ConsumerState<_StaffNameField> {
  late final _name = TextEditingController(
    text: widget.member.personName ?? '',
  );
  late var _saved = widget.member.personName ?? '';
  Timer? _typing;

  @override
  void dispose() {
    _typing?.cancel();
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    _typing?.cancel();
    final name = _name.text.trim();
    if (name == _saved) return;
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    try {
      await ref
          .read(clubRepositoryProvider)
          .saveStaffName(widget.eventId, widget.member.id, name);
      _saved = name;
      ref.invalidate(matsOverviewProvider(widget.eventId));
      toasts.show(
        l10n.saved,
        kind: ToastKind.success,
        duration: const Duration(seconds: 1),
      );
    } on DioException catch (e) {
      toasts.show(saveErrorMessage(l10n, e), kind: ToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final roles = widget.member.roles
        .map((r) => r == 'REFEREE' ? l10n.staffReferee : l10n.staffHelper)
        .join(', ');
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s),
      child: TextField(
        controller: _name,
        maxLength: 80,
        decoration: InputDecoration(
          labelText: '${widget.member.username} · $roles',
          hintText: l10n.staffNameHint,
          counterText: '',
        ),
        textCapitalization: TextCapitalization.words,
        onChanged: (_) {
          _typing?.cancel();
          _typing = Timer(const Duration(milliseconds: 800), _save);
        },
        onSubmitted: (_) => _save(),
      ),
    );
  }
}
