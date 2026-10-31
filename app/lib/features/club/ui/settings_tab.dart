import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/async_view.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../events/state/events_providers.dart';
import '../data/club_models.dart';
import '../data/club_repository.dart';
import '../state/club_providers.dart';
import 'club_panel_screen.dart';

const maxMats = 20;
const maxGroupsPerMatLimit = 4;

/// Event name and date, mats with their referee, and multigroup. Categories are shown, not edited.
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
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial.name);
  late var _date = widget.initial.date;
  late var _maxGroups = widget.initial.maxGroupsPerMat;
  late var _matReferees = [...widget.initial.matReferees];
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final text = Theme.of(context).textTheme;
    final settings = widget.initial;
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          TextFormField(
            controller: _name,
            decoration: InputDecoration(labelText: l10n.settingsName),
            maxLength: 120,
            validator: (v) =>
                v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
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
          const SizedBox(height: AppSpacing.l),
          Text(l10n.settingsMaxGroups, style: text.titleSmall),
          Text(l10n.settingsMaxGroupsHint, style: text.bodySmall),
          const SizedBox(height: AppSpacing.s),
          SegmentedButton<int>(
            segments: [
              for (var n = 1; n <= maxGroupsPerMatLimit; n++)
                ButtonSegment(value: n, label: Text('$n')),
            ],
            selected: {_maxGroups},
            onSelectionChanged: (s) => setState(() => _maxGroups = s.single),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.clubMats, style: text.titleMedium),
          for (final (i, refereeId) in _matReferees.indexed)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s),
              child: DropdownButtonFormField<String?>(
                initialValue: refereeId,
                decoration: InputDecoration(
                  labelText:
                      '${l10n.matTitle(i + 1)} · ${l10n.settingsReferee}',
                ),
                items: [
                  DropdownMenuItem(child: Text(l10n.matNoReferee)),
                  for (final r in settings.referees)
                    DropdownMenuItem(value: r.id, child: Text(r.username)),
                ],
                onChanged: (id) => setState(() => _matReferees[i] = id),
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
                    : () => setState(() => _matReferees.add(null)),
              ),
              TextButton.icon(
                icon: const Icon(Icons.remove),
                label: Text(l10n.settingsRemoveMat),
                onPressed: _matReferees.length <= 1
                    ? null
                    : () => setState(() => _matReferees.removeLast()),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.categoriesTitle, style: text.titleMedium),
          for (final c in settings.categories)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.categoryRange(c.name, c.minAge, c.maxAge)),
            ),
          const SizedBox(height: AppSpacing.l),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(l10n.save),
            ),
          ),
        ],
      ),
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

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(clubRepositoryProvider)
          .saveSettings(
            widget.eventId,
            name: _name.text.trim(),
            date: _date,
            maxGroupsPerMat: _maxGroups,
            matReferees: _matReferees,
          );
      if (!mounted) return;
      setState(() => _matReferees = [...saved.matReferees]);
      ref
        ..invalidate(eventSettingsProvider(widget.eventId))
        ..invalidate(myEventsProvider)
        ..invalidate(matsOverviewProvider(widget.eventId))
        ..invalidate(participantsProvider(widget.eventId));
      messenger.showSnackBar(SnackBar(content: Text(l10n.saved)));
    } on DioException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(saveErrorMessage(l10n, e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
