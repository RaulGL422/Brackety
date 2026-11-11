import 'dart:async';

import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/async_view.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/ui/widgets/confirm_dialog.dart';
import '../../events/state/events_providers.dart';
import '../data/club_models.dart';
import '../data/club_repository.dart';
import '../state/club_providers.dart';
import 'categories_editor.dart';
import 'club_panel_screen.dart';

const maxMats = 20;

/// Event name and date, mats with their referee, and the categories.
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
  Timer? _nameTyping;
  var _saving = false;
  var _changedWhileSaving = false;

  @override
  void dispose() {
    _nameTyping?.cancel();
    _name.dispose();
    super.dispose();
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
            // Saves once the club stops typing, not on every key.
            onChanged: (_) {
              _nameTyping?.cancel();
              _nameTyping = Timer(const Duration(milliseconds: 800), _save);
            },
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
          Text(l10n.clubMats, style: text.titleMedium),
          for (final (i, refereeId) in _matReferees.indexed)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s),
              child: DropdownButtonFormField<String?>(
                // A new key when the value changes, so a refused change shows the saved referee again.
                key: ValueKey('$i:$refereeId'),
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
                onChanged: (id) => _change(() => _matReferees[i] = id),
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
          Text(l10n.categoriesTitle, style: text.titleMedium),
          CategoriesEditor(
            eventId: widget.eventId,
            categories: settings.categories,
          ),
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

  /// One save at a time; changes made meanwhile go in the next one.
  Future<void> _save() async {
    _nameTyping?.cancel();
    if (_name.text.trim().isEmpty) return;
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
            );
      } while (_changedWhileSaving && mounted);
      ref
        ..invalidate(eventSettingsProvider(widget.eventId))
        ..invalidate(myEventsProvider)
        ..invalidate(matsOverviewProvider(widget.eventId))
        ..invalidate(participantsProvider(widget.eventId));
      toasts.show(
        l10n.saved,
        kind: ToastKind.success,
        duration: const Duration(seconds: 1),
      );
    } on DioException catch (e) {
      toasts.show(saveErrorMessage(l10n, e), kind: ToastKind.error);
      if (mounted) _showSaved();
    } finally {
      _saving = false;
    }
  }

  void _showSaved() => setState(() {
    _name.text = _saved.name;
    _date = _saved.date;
    _matReferees = [..._saved.matReferees];
  });
}
