import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../events/data/measure_rules.dart';
import '../../events/state/events_providers.dart';
import '../data/club_repository.dart';
import '../data/event_settings.dart';
import '../state/club_providers.dart';

/// Whether the event asks for weight and height (F2-1): as its sport, off, optional or required. Saved at once,
/// as the rest of the settings.
class MeasuresEditor extends ConsumerStatefulWidget {
  const MeasuresEditor({
    super.key,
    required this.eventId,
    required this.settings,
  });

  final String eventId;
  final EventSettings settings;

  @override
  ConsumerState<MeasuresEditor> createState() => _MeasuresEditorState();
}

class _MeasuresEditorState extends ConsumerState<MeasuresEditor> {
  late MeasureRequirement? _weight = widget.settings.weightChoice;
  late MeasureRequirement? _height = widget.settings.heightChoice;
  var _saving = false;

  Future<void> _save({
    required MeasureRequirement? weight,
    required MeasureRequirement? height,
  }) async {
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    setState(() {
      _weight = weight;
      _height = height;
      _saving = true;
    });
    try {
      await ref
          .read(clubRepositoryProvider)
          .saveMeasures(widget.eventId, weight: weight, height: height);
      ref
        ..invalidate(eventSettingsProvider(widget.eventId))
        ..invalidate(myEventProvider(widget.eventId));
      toasts.show(l10n.saved, duration: const Duration(seconds: 1));
    } on DioException {
      toasts.show(l10n.saveError, kind: ToastKind.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = widget.settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.measuresHint),
        const SizedBox(height: AppSpacing.s),
        _Choice(
          label: l10n.measureWeight,
          value: _weight,
          sport: s.sportWeight,
          onChanged: _saving ? null : (v) => _save(weight: v, height: _height),
        ),
        const SizedBox(height: AppSpacing.s),
        _Choice(
          label: l10n.measureHeight,
          value: _height,
          sport: s.sportHeight,
          onChanged: _saving ? null : (v) => _save(weight: _weight, height: v),
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.value,
    required this.sport,
    required this.onChanged,
  });

  final String label;

  /// Null follows the sport.
  final MeasureRequirement? value;
  final MeasureRequirement sport;
  final ValueChanged<MeasureRequirement?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<MeasureRequirement?>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        DropdownMenuItem(
          child: Text(
            l10n.requirementSport(requirementText(l10n, sport)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        for (final r in MeasureRequirement.values)
          DropdownMenuItem(value: r, child: Text(requirementText(l10n, r))),
      ],
      onChanged: onChanged,
    );
  }
}

String requirementText(AppLocalizations l10n, MeasureRequirement r) =>
    switch (r) {
      MeasureRequirement.off => l10n.requirementOff,
      MeasureRequirement.optional => l10n.requirementOptional,
      MeasureRequirement.required => l10n.requirementRequired,
    };
