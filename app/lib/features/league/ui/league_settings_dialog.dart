import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../events/state/events_providers.dart';
import '../data/league_models.dart';
import '../data/league_repository.dart';
import '../state/league_providers.dart';

/// The league's name and its podiums: one for every category, and those categories with their own.
Future<void> showLeagueSettings(
  BuildContext context,
  String eventId,
  League league,
) => showDialog<void>(
  context: context,
  builder: (_) => _LeagueSettingsDialog(eventId: eventId, league: league),
);

class _LeagueSettingsDialog extends ConsumerStatefulWidget {
  const _LeagueSettingsDialog({required this.eventId, required this.league});

  final String eventId;
  final League league;

  @override
  ConsumerState<_LeagueSettingsDialog> createState() =>
      _LeagueSettingsDialogState();
}

class _LeagueSettingsDialogState extends ConsumerState<_LeagueSettingsDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.league.name);
  late var _podium = widget.league.podium;

  /// Category name → its own podium; categories left out use [_podium].
  late final _own = {
    for (final c in widget.league.categoryPodiums) c.categoryName: c.podium,
  };
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return AlertDialog(
      actionsOverflowDirection: VerticalDirection.up,
      actionsOverflowButtonSpacing: 8,
      title: Text(l10n.leagueEdit),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(labelText: l10n.leagueName),
                  maxLength: 120,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: AppSpacing.m),
                Text(l10n.leaguePodium, style: text.titleSmall),
                Text(l10n.leaguePodiumHint, style: text.bodySmall),
                const SizedBox(height: AppSpacing.s),
                _PodiumFields(
                  podium: _podium,
                  onChanged: (p) => setState(() => _podium = p),
                ),
                if (widget.league.categoryNames.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.l),
                  Text(l10n.leagueCategoryPodiums, style: text.titleSmall),
                  for (final category in widget.league.categoryNames) ...[
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(category),
                      subtitle: Text(l10n.leagueOwnPodium),
                      value: _own.containsKey(category),
                      onChanged: (own) => setState(
                        () => own!
                            ? _own[category] = _podium
                            : _own.remove(category),
                      ),
                    ),
                    if (_own[category] case final podium?)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.xl,
                          bottom: AppSpacing.s,
                        ),
                        child: _PodiumFields(
                          podium: podium,
                          onChanged: (p) => setState(() => _own[category] = p),
                        ),
                      ),
                  ],
                ],
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
        FilledButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
      ],
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(leagueRepositoryProvider)
          .save(
            widget.eventId,
            name: _name.text.trim(),
            podium: _podium,
            categoryPodiums: [
              for (final MapEntry(:key, :value) in _own.entries)
                CategoryPodium(categoryName: key, podium: value),
            ],
          );
      ref
        ..invalidate(leagueProvider(widget.eventId))
        ..invalidate(leagueStandingsProvider(widget.eventId))
        ..invalidate(myEventsProvider);
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      if (mounted) setState(() => _saving = false);
      toasts.show(
        e.response?.statusCode == 400 ? l10n.saveInvalid : l10n.saveError,
        kind: ToastKind.error,
      );
    }
  }
}

/// How many golds, silvers and bronzes, 0 to 10 each.
class _PodiumFields extends StatelessWidget {
  const _PodiumFields({required this.podium, required this.onChanged});

  final Podium podium;
  final ValueChanged<Podium> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget field(String label, int value, Podium Function(int) change) =>
        SizedBox(
          width: 120,
          child: DropdownButtonFormField<int>(
            initialValue: value,
            decoration: InputDecoration(labelText: label),
            items: [
              for (var i = 0; i <= 10; i++)
                DropdownMenuItem(value: i, child: Text('$i')),
            ],
            onChanged: (v) => onChanged(change(v!)),
          ),
        );
    return Wrap(
      spacing: AppSpacing.m,
      runSpacing: AppSpacing.s,
      children: [
        field(
          l10n.medalGold,
          podium.firsts,
          (v) =>
              Podium(firsts: v, seconds: podium.seconds, thirds: podium.thirds),
        ),
        field(
          l10n.medalSilver,
          podium.seconds,
          (v) =>
              Podium(firsts: podium.firsts, seconds: v, thirds: podium.thirds),
        ),
        field(
          l10n.medalBronze,
          podium.thirds,
          (v) =>
              Podium(firsts: podium.firsts, seconds: podium.seconds, thirds: v),
        ),
      ],
    );
  }
}
