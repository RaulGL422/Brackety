import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../auth/ui/widgets/birth_date_field.dart';
import '../../club/data/sex.dart';
import '../../club/ui/measure_fields.dart';
import '../data/import_models.dart';

/// Edits a row of the list, or adds one when [row] is null. Returns the row, or null if cancelled.
Future<ImportRow?> showRowDialog(BuildContext context, {ImportRow? row}) =>
    showDialog<ImportRow>(
      context: context,
      builder: (_) => _RowDialog(row: row),
    );

class _RowDialog extends StatefulWidget {
  const _RowDialog({this.row});

  final ImportRow? row;

  @override
  State<_RowDialog> createState() => _RowDialogState();
}

class _RowDialogState extends State<_RowDialog> {
  final _form = GlobalKey<FormState>();
  late final _firstName = TextEditingController(text: widget.row?.firstName);
  late final _lastName = TextEditingController(text: widget.row?.lastName);
  late final _height = TextEditingController(
    text: widget.row?.heightCm?.toString(),
  );
  late final _weight = TextEditingController(
    text: widget.row?.weightKg?.toString(),
  );
  late DateTime? _birthDate = widget.row?.birthDate;
  late Sex? _sex = widget.row?.sex;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final row = widget.row ?? const ImportRow();
    Navigator.of(context).pop(
      row.edited(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        birthDate: _birthDate,
        sex: _sex,
        heightCm: int.tryParse(_height.text.trim()),
        weightKg: parseWeight(_weight.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String? required(String? v) =>
        v == null || v.trim().isEmpty ? l10n.fieldRequired : null;
    return AlertDialog(
      scrollable: true,
      actionsOverflowDirection: VerticalDirection.up,
      actionsOverflowButtonSpacing: 8,
      title: Text(widget.row == null ? l10n.importAddRow : l10n.importEditRow),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _firstName,
                  decoration: InputDecoration(labelText: l10n.firstName),
                  textCapitalization: TextCapitalization.words,
                  validator: required,
                ),
                TextFormField(
                  controller: _lastName,
                  decoration: InputDecoration(labelText: l10n.lastName),
                  textCapitalization: TextCapitalization.words,
                  validator: required,
                ),
                BirthDateField(
                  today: DateTime.now(),
                  initialValue: _birthDate,
                  validator: (d) => d == null ? l10n.fieldRequired : null,
                  onChanged: (d) => _birthDate = d,
                ),
                SexField(
                  initialValue: _sex,
                  requiredText: l10n.fieldRequired,
                  onChanged: (sex) => _sex = sex,
                ),
                HeightField(controller: _height),
                WeightField(controller: _weight),
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
