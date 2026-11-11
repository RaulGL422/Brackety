import 'package:brackety_core/brackety_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../grouping/state/grouping_providers.dart';
import '../data/club_models.dart';
import '../data/club_repository.dart';
import '../state/club_providers.dart';

/// The event's categories (docs/modulos/prototipo-f1-equipos.md): age band and whether they
/// compete individually or as teams. Every change is saved at once, as the rest of the settings.
class CategoriesEditor extends ConsumerStatefulWidget {
  const CategoriesEditor({
    super.key,
    required this.eventId,
    required this.categories,
  });

  final String eventId;
  final List<EventCategory> categories;

  @override
  ConsumerState<CategoriesEditor> createState() => _CategoriesEditorState();
}

class _CategoriesEditorState extends ConsumerState<CategoriesEditor> {
  late var _categories = widget.categories;
  var _saving = false;

  @override
  void didUpdateWidget(CategoriesEditor old) {
    super.didUpdateWidget(old);
    if (old.categories != widget.categories) _categories = widget.categories;
  }

  Future<void> _save(List<EventCategory> next) async {
    final l10n = AppLocalizations.of(context);
    final toasts = Toasts.of(context);
    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(clubRepositoryProvider)
          .saveCategories(widget.eventId, next);
      if (mounted) setState(() => _categories = saved);
      ref
        ..invalidate(eventSettingsProvider(widget.eventId))
        ..invalidate(participantsProvider(widget.eventId))
        ..invalidate(categoriesProvider(widget.eventId));
      toasts.show(l10n.saved, duration: const Duration(seconds: 1));
    } on DioException catch (e) {
      toasts.show(switch (e.response?.statusCode) {
        409 => l10n.categoriesInUse,
        400 => l10n.categoriesInvalid,
        _ => l10n.saveError,
      }, kind: ToastKind.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _edit(int? index) async {
    final edited = await showDialog<EventCategory>(
      context: context,
      builder: (_) =>
          _CategoryDialog(initial: index == null ? null : _categories[index]),
    );
    if (edited == null) return;
    await _save(
      index == null
          ? [..._categories, edited]
          : ([..._categories]..[index] = edited),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, c) in _categories.indexed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.categoryRange(c.name, c.minAge, c.maxAge)),
            subtitle: Text(
              '${c.isTeam ? l10n.categoryTeams(c.teamSize!) : l10n.categoryIndividual}'
              ' · ${l10n.categoryGroupSize(c.groupSize)}',
            ),
            onTap: _saving ? null : () => _edit(i),
            trailing: IconButton(
              tooltip: l10n.categoryRemove,
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving || _categories.length == 1
                  ? null
                  : () => _save([..._categories]..removeAt(i)),
            ),
          ),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: Text(l10n.categoryAdd),
          onPressed: _saving ? null : () => _edit(null),
        ),
      ],
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.initial});

  final EventCategory? initial;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _min = TextEditingController(
    text: widget.initial?.minAge.toString(),
  );
  late final _max = TextEditingController(
    text: widget.initial?.maxAge.toString(),
  );
  late var _teamSize = widget.initial?.teamSize;

  @override
  void dispose() {
    _name.dispose();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop(
      EventCategory(
        id: widget.initial?.id,
        name: _name.text.trim(),
        minAge: int.parse(_min.text),
        maxAge: int.parse(_max.text),
        teamSize: _teamSize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String? required(String? v) =>
        v == null || v.trim().isEmpty ? l10n.fieldRequired : null;
    String? age(String? v) {
      final n = int.tryParse(v ?? '');
      return n == null || n > 120 ? l10n.fieldRequired : null;
    }

    return AlertDialog(
      actionsOverflowDirection: VerticalDirection.up,
      actionsOverflowButtonSpacing: 8,
      title: Text(
        widget.initial == null ? l10n.categoryAdd : l10n.categoryEdit,
      ),
      // Wide enough for the age labels; narrower screens shrink it to fit.
      content: SizedBox(
        width: 360,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  // No counter: it would sit on the age labels just below.
                  decoration: InputDecoration(
                    labelText: l10n.categoryNameLabel,
                    counterText: '',
                  ),
                  maxLength: 40,
                  validator: required,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _min,
                        decoration: InputDecoration(
                          labelText: l10n.categoryMinAge,
                          suffixText: l10n.categoryAgeSuffix,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: age,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: TextFormField(
                        controller: _max,
                        decoration: InputDecoration(
                          labelText: l10n.categoryMaxAge,
                          suffixText: l10n.categoryAgeSuffix,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) {
                          final error = age(v);
                          if (error != null) return error;
                          final min = int.tryParse(_min.text);
                          return min != null && min > int.parse(v!)
                              ? l10n.categoryAgesInvalid
                              : null;
                        },
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.categoryByTeams),
                  value: _teamSize != null,
                  onChanged: (on) => setState(() => _teamSize = on ? 3 : null),
                ),
                if (_teamSize != null)
                  DropdownButtonFormField<int>(
                    initialValue: _teamSize,
                    decoration: InputDecoration(
                      labelText: l10n.categoryTeamSize,
                    ),
                    items: [
                      for (var n = 2; n <= 5; n++)
                        DropdownMenuItem(value: n, child: Text('$n')),
                    ],
                    onChanged: (n) => setState(() => _teamSize = n),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.ok)),
      ],
    );
  }
}
