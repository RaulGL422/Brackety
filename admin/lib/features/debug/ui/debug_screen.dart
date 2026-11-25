import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/page_header.dart';
import '../../../core/run_action.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/debug_api.dart';
import '../state/debug_providers.dart';

/// The debug environment's tab (docs/modulos/entornos.md): load a scenario, move the day, save and restore copies.
class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  void _refresh(WidgetRef ref) => ref
    ..invalidate(debugStatusProvider)
    ..invalidate(scenariosProvider)
    ..invalidate(snapshotsProvider);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.l),
          children: [
            PageHeader(title: l10n.debugTitle, onRefresh: () => _refresh(ref)),
            const SizedBox(height: AppSpacing.m),
            const _Day(),
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.debugScenarios, style: text.titleMedium),
            Text(l10n.debugScenariosHint),
            AsyncView(
              value: ref.watch(scenariosProvider),
              onRetry: () => ref.invalidate(scenariosProvider),
              data: (scenarios) => Column(
                children: [
                  for (final s in scenarios)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.name),
                      subtitle: Text(s.description),
                      trailing: FilledButton.tonal(
                        onPressed: () => _load(context, ref, s),
                        child: Text(l10n.debugLoad),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.debugCopies, style: text.titleMedium),
            Text(l10n.debugCopiesHint),
            const _SaveCopy(),
            AsyncView(
              value: ref.watch(snapshotsProvider),
              onRetry: () => ref.invalidate(snapshotsProvider),
              data: (copies) => Column(
                children: [
                  for (final c in copies)
                    _CopyTile(copy: c, onChanged: () => _refresh(ref)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _load(BuildContext context, WidgetRef ref, Scenario s) async {
    final l10n = AppLocalizations.of(context);
    final today = await showDialog<_LoadChoice>(
      context: context,
      builder: (_) => _LoadDialog(scenario: s.name),
    );
    if (today == null || !context.mounted) return;
    await runAction(
      context,
      () => ref.read(debugApiProvider).load(s.name, today: today.day),
      done: (_) => l10n.debugLoaded(s.name),
      notFound: l10n.debugGone,
    );
    _refresh(ref);
  }
}

/// The day the server lives in: real or simulated.
class _Day extends ConsumerWidget {
  const _Day();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final status = ref.watch(debugStatusProvider).value;
    if (status == null) return const SizedBox.shrink();
    final date = DateFormat.yMMMMd(locale).format(status.today);
    Future<void> move(DateTime? day) async {
      await runAction(
        context,
        () => ref.read(debugApiProvider).moveClock(day),
        done: (_) => CoreLocalizations.of(context).saved,
        notFound: l10n.debugGone,
      );
      ref.invalidate(debugStatusProvider);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Wrap(
          spacing: AppSpacing.m,
          runSpacing: AppSpacing.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              [
                l10n.debugScenarioNow(status.scenario ?? '–'),
                status.simulated
                    ? l10n.debugSimulatedDay(date)
                    : l10n.debugRealDay(date),
              ].join(' · '),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.event_outlined),
              label: Text(l10n.debugMoveDay),
              onPressed: () async {
                final day = await showDatePicker(
                  context: context,
                  initialDate: status.today,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (day != null) await move(day);
              },
            ),
            if (status.simulated)
              TextButton(
                onPressed: () => move(null),
                child: Text(l10n.debugBackToToday),
              ),
          ],
        ),
      ),
    );
  }
}

class _SaveCopy extends ConsumerStatefulWidget {
  const _SaveCopy();

  @override
  ConsumerState<_SaveCopy> createState() => _SaveCopyState();
}

class _SaveCopyState extends ConsumerState<_SaveCopy> {
  final _name = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    await runAction(
      context,
      () => ref.read(debugApiProvider).save(name),
      done: (_) => l10n.debugCopySaved(name),
      notFound: l10n.debugGone,
    );
    _name.clear();
    ref.invalidate(snapshotsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _form,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l10n.debugCopyName),
              validator: (v) =>
                  RegExp(r'^[a-z0-9_]{1,40}$').hasMatch(v?.trim() ?? '')
                  ? null
                  : l10n.debugCopyNameInvalid,
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s),
            child: FilledButton(
              onPressed: _save,
              child: Text(CoreLocalizations.of(context).save),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyTile extends ConsumerWidget {
  const _CopyTile({required this.copy, required this.onChanged});

  final Snapshot copy;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(copy.name),
      subtitle: Text(
        [
          if (copy.savedAt != null)
            DateFormat.yMd(locale).add_Hm().format(copy.savedAt!.toLocal()),
          ?copy.scenario,
        ].join(' · '),
      ),
      trailing: Wrap(
        spacing: AppSpacing.xs,
        children: [
          TextButton(
            onPressed: () async {
              if (!await confirmAction(
                context,
                title: l10n.debugRestoreTitle(copy.name),
                body: l10n.debugWipeWarning,
                confirmLabel: l10n.debugRestore,
              )) {
                return;
              }
              if (!context.mounted) return;
              await runAction(
                context,
                () => ref.read(debugApiProvider).restore(copy.name),
                done: (_) => l10n.debugRestored(copy.name),
                notFound: l10n.debugGone,
              );
              onChanged();
            },
            child: Text(l10n.debugRestore),
          ),
          IconButton(
            tooltip: l10n.debugDeleteCopy,
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (!await confirmAction(
                context,
                title: l10n.debugDeleteTitle(copy.name),
                body: l10n.debugDeleteBody,
                confirmLabel: l10n.debugDeleteCopy,
              )) {
                return;
              }
              if (!context.mounted) return;
              await runAction(
                context,
                () => ref.read(debugApiProvider).delete(copy.name),
                done: (_) => l10n.debugCopyDeleted(copy.name),
                notFound: l10n.debugGone,
              );
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}

/// [day]: the simulated day to load it on, or null for today.
class _LoadChoice {
  const _LoadChoice(this.day);

  final DateTime? day;
}

/// Everything is wiped: the scenario's name must be typed again.
class _LoadDialog extends StatefulWidget {
  const _LoadDialog({required this.scenario});

  final String scenario;

  @override
  State<_LoadDialog> createState() => _LoadDialogState();
}

class _LoadDialogState extends State<_LoadDialog> {
  final _confirm = TextEditingController();
  DateTime? _day;

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final typed = _confirm.text.trim() == widget.scenario;
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.debugLoadTitle(widget.scenario)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.debugWipeWarning),
            const SizedBox(height: AppSpacing.m),
            TextField(
              controller: _confirm,
              decoration: InputDecoration(
                labelText: l10n.debugTypeName(widget.scenario),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.m),
            OutlinedButton.icon(
              icon: const Icon(Icons.event_outlined),
              label: Text(
                _day == null
                    ? l10n.debugOnToday
                    : l10n.debugOnDay(DateFormat.yMd(locale).format(_day!)),
              ),
              onPressed: () async {
                final day = await showDatePicker(
                  context: context,
                  initialDate: _day ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (day != null) setState(() => _day = day);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(CoreLocalizations.of(context).cancel),
        ),
        FilledButton(
          onPressed: typed
              ? () => Navigator.pop(context, _LoadChoice(_day))
              : null,
          child: Text(l10n.debugLoad),
        ),
      ],
    );
  }
}
