import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error_codes.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../events/data/settings_input.dart';
import '../../events/state/events_providers.dart';
import '../data/league_models.dart';
import '../data/league_repository.dart';
import 'event_fields.dart';

/// Every sport, with or without a scoreboard yet.
final _sportsProvider = FutureProvider.autoDispose<List<Sport>>(
  (ref) => ref.watch(leagueRepositoryProvider).sports(),
);

/// Creates a standalone event (name, day, sport and mats) and opens its panel: the caller is
/// its club, and adds categories, people and referees there.
Future<void> showNewEventDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _NewEventDialog());

class _NewEventDialog extends ConsumerStatefulWidget {
  const _NewEventDialog();

  @override
  ConsumerState<_NewEventDialog> createState() => _NewEventDialogState();
}

class _NewEventDialogState extends ConsumerState<_NewEventDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mats = TextEditingController(text: '1');
  var _date = DateUtils.dateOnly(DateTime.now());
  String? _sport;
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _mats.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      scrollable: true,
      actionsOverflowDirection: VerticalDirection.up,
      actionsOverflowButtonSpacing: 8,
      title: Text(l10n.newEventTitle),
      content: SizedBox(
        width: 400,
        child: AsyncView(
          value: ref.watch(_sportsProvider),
          onRetry: () => ref.invalidate(_sportsProvider),
          data: _fields,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(CoreLocalizations.of(context).cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _create,
          child: Text(l10n.newEventCreate),
        ),
      ],
    );
  }

  Widget _fields(List<Sport> sports) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.m,
        children: [
          Text(l10n.newEventHint),
          TextFormField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.newEventName),
            maxLength: 120,
            validator: (v) =>
                v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
          ),
          DateField(date: _date, onChanged: (d) => setState(() => _date = d)),
          SportField(
            value: _sport,
            sports: sports,
            validator: (s) => s == null ? l10n.fieldRequired : null,
            onChanged: (s) => setState(() => _sport = s),
          ),
          TextFormField(
            controller: _mats,
            decoration: InputDecoration(labelText: l10n.newEventMats),
            keyboardType: TextInputType.number,
            validator: (v) => _parseMats(v ?? '') == null
                ? l10n.newEventMatsInvalid(maxMats)
                : null,
          ),
        ],
      ),
    );
  }

  static int? _parseMats(String text) {
    final mats = int.tryParse(text.trim());
    return mats != null && mats >= 1 && mats <= maxMats ? mats : null;
  }

  Future<void> _create() async {
    final form = _form.currentState;
    if (form == null || !form.validate()) return;
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    final router = GoRouter.of(context);
    setState(() => _saving = true);
    try {
      final event = await ref
          .read(leagueRepositoryProvider)
          .createEvent(
            name: _name.text.trim(),
            date: _date,
            sport: _sport!,
            mats: _parseMats(_mats.text)!,
          );
      ref.invalidate(myEventsProvider);
      if (mounted) Navigator.pop(context);
      toasts.show(l10n.newEventDone, kind: ToastKind.success);
      router.go('/events/${event.eventId}/club');
    } on DioException catch (e) {
      if (mounted) setState(() => _saving = false);
      toasts.show(
        errorMessage(
          l10n,
          e,
          e.response?.statusCode == 400 ? l10n.saveInvalid : l10n.saveError,
        ),
        kind: ToastKind.error,
      );
    }
  }
}
