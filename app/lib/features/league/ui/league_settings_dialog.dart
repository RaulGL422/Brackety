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
      scrollable: true,
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
                _PodiumPicker(
                  podium: _podium,
                  onChanged: (p) => setState(() => _podium = p),
                ),
                if (widget.league.categoryNames.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.l),
                  Text(l10n.leagueCategoryPodiums, style: text.titleSmall),
                  Text(l10n.leagueCategoryPodiumsHint, style: text.bodySmall),
                  for (final category in widget.league.categoryNames)
                    _CategoryPodium(
                      category: category,
                      general: _podium,
                      own: _own[category],
                      onChanged: (p) => setState(
                        () => p == null
                            ? _own.remove(category)
                            : _own[category] = p,
                      ),
                    ),
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

/// The usual podiums, one tap each: 1 gold, 1 silver and 1 bronze, or 1·1·2 (two bronzes, as in
/// martial arts).
const _presets = [
  Podium(firsts: 1, seconds: 1, thirds: 1),
  Podium(firsts: 1, seconds: 1, thirds: 2),
];

bool _same(Podium a, Podium b) =>
    a.firsts == b.firsts && a.seconds == b.seconds && a.thirds == b.thirds;

String _short(Podium p) => '${p.firsts}·${p.seconds}·${p.thirds}';

/// The usual podiums as chips, or "Other" with a counter per metal.
class _PodiumPicker extends StatefulWidget {
  const _PodiumPicker({
    super.key,
    required this.podium,
    required this.onChanged,
  });

  final Podium podium;
  final ValueChanged<Podium> onChanged;

  @override
  State<_PodiumPicker> createState() => _PodiumPickerState();
}

class _PodiumPickerState extends State<_PodiumPicker> {
  late var _other = !_presets.any((p) => _same(p, widget.podium));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final podium = widget.podium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            for (final preset in _presets)
              ChoiceChip(
                label: Text(
                  l10n.podiumPreset(
                    preset.firsts,
                    preset.seconds,
                    preset.thirds,
                  ),
                ),
                selected: !_other && _same(preset, podium),
                onSelected: (_) {
                  setState(() => _other = false);
                  widget.onChanged(preset);
                },
              ),
            ChoiceChip(
              label: Text(l10n.podiumOther),
              selected: _other,
              onSelected: (_) => setState(() => _other = true),
            ),
          ],
        ),
        if (_other) ...[
          const SizedBox(height: AppSpacing.s),
          _Counter(
            label: l10n.medalGold,
            value: podium.firsts,
            onChanged: (v) => widget.onChanged(
              Podium(firsts: v, seconds: podium.seconds, thirds: podium.thirds),
            ),
          ),
          _Counter(
            label: l10n.medalSilver,
            value: podium.seconds,
            onChanged: (v) => widget.onChanged(
              Podium(firsts: podium.firsts, seconds: v, thirds: podium.thirds),
            ),
          ),
          _Counter(
            label: l10n.medalBronze,
            value: podium.thirds,
            onChanged: (v) => widget.onChanged(
              Podium(firsts: podium.firsts, seconds: podium.seconds, thirds: v),
            ),
          ),
        ],
      ],
    );
  }
}

/// One category: the general podium (most of them) or its own, said at a glance.
class _CategoryPodium extends StatelessWidget {
  const _CategoryPodium({
    required this.category,
    required this.general,
    required this.own,
    required this.onChanged,
  });

  final String category;
  final Podium general;
  final Podium? own;

  /// Null: back to the general one.
  final ValueChanged<Podium?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final own = this.own;
    // Name over the choice: side by side they did not fit a phone.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.s),
        Text(category, style: Theme.of(context).textTheme.titleSmall),
        DropdownButton<bool>(
          isExpanded: true,
          value: own != null,
          items: [
            DropdownMenuItem(
              value: false,
              child: Text(l10n.podiumAsGeneral(_short(general))),
            ),
            DropdownMenuItem(value: true, child: Text(l10n.podiumOwn)),
          ],
          onChanged: (custom) => onChanged(custom! ? general : null),
        ),
        if (own != null)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.l,
              bottom: AppSpacing.s,
            ),
            child: _PodiumPicker(
              key: ValueKey(category),
              podium: own,
              onChanged: onChanged,
            ),
          ),
      ],
    );
  }
}

/// − value + for one metal, 0 to 10.
class _Counter extends StatelessWidget {
  const _Counter({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          tooltip: l10n.podiumLess(label),
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          tooltip: l10n.podiumMore(label),
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < 10 ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}
