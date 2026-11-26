import 'dart:async';

import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../auth/data/api_error.dart';
import '../../events/data/club_repository.dart';
import '../../events/data/event_settings.dart';
import '../../events/data/my_event.dart';
import '../../events/data/settings_input.dart';
import '../../events/data/staff_member.dart';
import '../../events/state/club_providers.dart';
import '../../events/state/events_providers.dart';
import '../../league/state/league_providers.dart';
import '../../rulebook/rulebook_ui.dart';
import '../../staff/data/staff_repository.dart';
import '../../staff/ui/qr_access.dart';
import '../../staff/ui/qr_access_section.dart';
import '../../staff/ui/staff_section.dart';
import 'categories_editor.dart';
import 'club_panel_screen.dart';
import 'export_audit_section.dart';
import 'measures_editor.dart';
import 'organizations_editor.dart';
import 'warning_reasons_editor.dart';

/// Event name and date, match length, points limit, superiority gap and attendance points, mats with their referee, and the
/// categories.
/// The event's fields save with a button (an autosave that silently skipped an invalid field lost a new mat, Raul
/// 2026-11-23); the sections below them save on their own.
class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key, required this.eventId, required this.unsaved});

  final String eventId;

  /// True while the event's fields have changes not saved, for the panel to ask before leaving.
  final ValueNotifier<bool> unsaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = eventSettingsProvider(eventId);
    return AsyncView(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      data: (settings) =>
          _SettingsForm(eventId: eventId, initial: settings, unsaved: unsaved),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({
    required this.eventId,
    required this.initial,
    required this.unsaved,
  });

  final String eventId;
  final EventSettings initial;
  final ValueNotifier<bool> unsaved;

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
  final _form = GlobalKey<FormState>();
  var _saving = false;

  @override
  void dispose() {
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

  // A QR access for a mat puts its referee there on the server: show it, unless the club has changes to save.
  @override
  void didUpdateWidget(covariant _SettingsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_saving && !_dirty && widget.initial != oldWidget.initial) {
      _saved = widget.initial;
      _fillFromSaved();
    }
  }

  bool get _dirty =>
      _name.text.trim() != _saved.name ||
      _date != _saved.date ||
      !listEquals(_matReferees, _saved.matReferees) ||
      _length.text.trim() != formatMatchLength(_saved.matchLength) ||
      _limit.text.trim() != _limitText(_saved.pointsLimit) ||
      _teamLength.text.trim() != formatMatchLength(_saved.teamMatchLength) ||
      _teamLimit.text.trim() != _limitText(_saved.teamPointsLimit) ||
      _gap.text.trim() != _limitText(_saved.superiorityGap) ||
      _minRest.text.trim() != '${_saved.minRest.inSeconds}' ||
      _attendance.text.trim() != '${_saved.attendancePoints}';

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

  /// Who has mat [i] on the server now (the QR changes the saved mats, not the edited ones).
  String? _refereeName(EventSettings settings, int i) {
    final id = _saved.matReferees.elementAtOrNull(i);
    return settings.referees.where((r) => r.id == id).firstOrNull?.label;
  }

  void _change(VoidCallback update) {
    setState(update);
    widget.unsaved.value = _dirty;
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.initial;
    return Form(
      key: _form,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          Expanded(child: _fields(context, settings)),
          if (_dirty || _saving)
            _SaveBar(saving: _saving, onDiscard: _discard, onSave: _save),
        ],
      ),
    );
  }

  Widget _fields(BuildContext context, EventSettings settings) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.l),
      children: [
        TextFormField(
          controller: _name,
          decoration: InputDecoration(labelText: l10n.settingsName),
          maxLength: 120,
          validator: (v) =>
              v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
          onChanged: (_) => _change(() {}),
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
          onChanged: (_) => _change(() {}),
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
          onChanged: (_) => _change(() {}),
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
          onChanged: (_) => _change(() {}),
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
          onChanged: (_) => _change(() {}),
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
          onChanged: (_) => _change(() {}),
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
          onChanged: (_) => _change(() {}),
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
          onChanged: (_) => _change(() {}),
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
                  replaces: _refereeName(settings, i),
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
        ExportAuditSection(eventId: widget.eventId),
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

  /// The labels of the fields that cannot be saved as they are.
  List<String> _invalidFields(AppLocalizations l10n) => [
    if (_name.text.trim().isEmpty) l10n.settingsName,
    if (parseMatchLength(_length.text) == null) l10n.settingsMatchLength,
    if (parsePointsLimit(_limit.text) == null) l10n.settingsPointsLimit,
    if (parseMatchLength(_teamLength.text) == null)
      l10n.settingsTeamMatchLength,
    if (parsePointsLimit(_teamLimit.text) == null) l10n.settingsTeamPointsLimit,
    if (parsePointsLimit(_gap.text, max: 100) == null)
      l10n.settingsSuperiorityGap,
    if (parseMinRest(_minRest.text) == null) l10n.settingsMinRest,
    if (parseAttendancePoints(_attendance.text) == null)
      l10n.leagueAttendancePoints,
  ];

  /// A refused save keeps what the club wrote, to fix it or discard it.
  Future<void> _save() async {
    if (_saving || !_dirty) return;
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    final invalid = _invalidFields(l10n);
    if (invalid.isNotEmpty) {
      _form.currentState?.validate();
      toasts.show(
        l10n.settingsFixFields(invalid.join(', ')),
        kind: ToastKind.error,
      );
      return;
    }
    final length = parseMatchLength(_length.text)!;
    final limit = parsePointsLimit(_limit.text)!;
    final teamLength = parseMatchLength(_teamLength.text)!;
    final teamLimit = parsePointsLimit(_teamLimit.text)!;
    final gap = parsePointsLimit(_gap.text, max: 100)!;
    final rulesChanged =
        length != _saved.matchLength ||
        limit != _saved.pointsLimit ||
        teamLength != _saved.teamMatchLength ||
        teamLimit != _saved.teamPointsLimit ||
        gap != _saved.superiorityGap;
    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(clubRepositoryProvider)
          .saveSettings(
            widget.eventId,
            name: _name.text.trim(),
            date: _date,
            matReferees: [..._matReferees],
            matchLength: length,
            pointsLimit: limit,
            attendancePoints: parseAttendancePoints(_attendance.text)!,
            teamMatchLength: teamLength,
            teamPointsLimit: teamLimit,
            minRest: parseMinRest(_minRest.text)!,
            superiorityGap: gap,
          );
      if (!mounted) return;
      _saved = saved;
      _fillFromSaved();
      ref
        ..invalidate(eventSettingsProvider(widget.eventId))
        ..invalidate(leagueStandingsProvider(widget.eventId))
        ..invalidate(myEventsProvider)
        ..invalidate(matsOverviewProvider(widget.eventId))
        ..invalidate(participantsProvider(widget.eventId));
      toasts.show(
        CoreLocalizations.of(context).saved,
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
    } finally {
      if (mounted) _change(() => _saving = false);
    }
  }

  void _discard() => _change(_fillFromSaved);

  void _fillFromSaved() {
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
  }
}

/// Below the event's fields while they have changes: discard them or save them.
class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.saving,
    required this.onDiscard,
    required this.onSave,
  });

  final bool saving;
  final VoidCallback onDiscard;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      elevation: 3,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.l,
            vertical: AppSpacing.s,
          ),
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              Text(l10n.settingsUnsaved),
              TextButton(
                onPressed: saving ? null : onDiscard,
                child: Text(l10n.settingsDiscard),
              ),
              FilledButton.icon(
                onPressed: saving ? null : onSave,
                icon: saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(CoreLocalizations.of(context).save),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
    final savedText = CoreLocalizations.of(context).saved;
    try {
      await ref
          .read(clubRepositoryProvider)
          .saveStaffName(widget.eventId, widget.member.id, name);
      _saved = name;
      ref.invalidate(matsOverviewProvider(widget.eventId));
      toasts.show(
        savedText,
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
