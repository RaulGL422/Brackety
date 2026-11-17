import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../club/ui/measure_fields.dart';
import '../../events/data/measure_rules.dart';
import '../../events/state/events_providers.dart';
import '../data/grouping_models.dart';
import '../data/grouping_repository.dart';

/// What the event asks of each participant, as the grouping screens read it.
MeasureRules measureRulesOf(WidgetRef ref, String eventId) =>
    ref.watch(myEventProvider(eventId)).value?.measures ?? const MeasureRules();

bool blockedByMeasures(MeasureRules rules, CategoryParticipant p) =>
    rules.blocks(weightKg: p.weightKg, heightCm: p.heightCm);

/// "9 años · 130 cm · sin peso": the age and each measure the event asks, missing ones said so.
String participantSummary(
  AppLocalizations l10n,
  String locale,
  MeasureRules rules,
  CategoryParticipant p,
) => [
  '${p.age} ${l10n.categoryAgeSuffix}',
  if (rules.height != MeasureRequirement.off)
    p.heightCm != null
        ? l10n.heightCm(p.heightCm!)
        : rules.height == MeasureRequirement.required
        ? l10n.heightMissing
        : l10n.heightUnknown,
  if (rules.weight != MeasureRequirement.off)
    p.weightKg != null
        ? weightText(l10n, locale, p.weightKg!)
        : rules.weight == MeasureRequirement.required
        ? l10n.weightMissing
        : l10n.weightUnknown,
].join(' · ');

/// The helper writes down [p]'s weight and height on the day. True once saved.
Future<bool> showMeasuresDialog(
  BuildContext context,
  String eventId,
  CategoryParticipant p,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => _MeasuresDialog(eventId: eventId, participant: p),
    ) ??
    false;

class _MeasuresDialog extends ConsumerStatefulWidget {
  const _MeasuresDialog({required this.eventId, required this.participant});

  final String eventId;
  final CategoryParticipant participant;

  @override
  ConsumerState<_MeasuresDialog> createState() => _MeasuresDialogState();
}

class _MeasuresDialogState extends ConsumerState<_MeasuresDialog> {
  final _form = GlobalKey<FormState>();
  late final _height = TextEditingController(
    text: widget.participant.heightCm?.toString(),
  );
  late final _weight = TextEditingController(
    text: widget.participant.weightKg?.toString(),
  );
  var _saving = false;

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(groupingRepositoryProvider)
          .measure(
            widget.eventId,
            widget.participant.id,
            heightCm: int.tryParse(_height.text.trim()),
            weightKg: parseWeight(_weight.text),
          );
      if (mounted) Navigator.pop(context, true);
    } on DioException {
      if (!mounted) return;
      setState(() => _saving = false);
      Toasts.of(context).show(l10n.saveError, kind: ToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rules = measureRulesOf(ref, widget.eventId);
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.measuresOf(widget.participant.fullName)),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (rules.height != MeasureRequirement.off)
                HeightField(controller: _height),
              if (rules.weight != MeasureRequirement.off)
                WeightField(controller: _weight),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
      ],
    );
  }
}
