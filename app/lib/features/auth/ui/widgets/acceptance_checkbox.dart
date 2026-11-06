import 'package:flutter/material.dart';

/// A required checkbox: the form does not validate until it is ticked.
class AcceptanceCheckbox extends FormField<bool> {
  AcceptanceCheckbox({
    super.key,
    required Widget title,
    required String requiredText,
    bool initialValue = false,
    ValueChanged<bool>? onChanged,
  }) : super(
         initialValue: initialValue,
         validator: (accepted) => accepted == true ? null : '',
         builder: (field) => _AcceptanceTile(
           field: field,
           title: title,
           requiredText: requiredText,
           onChanged: onChanged,
         ),
       );
}

class _AcceptanceTile extends StatelessWidget {
  const _AcceptanceTile({
    required this.field,
    required this.title,
    required this.requiredText,
    this.onChanged,
  });

  final FormFieldState<bool> field;
  final Widget title;
  final String requiredText;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CheckboxListTile(
      value: field.value,
      onChanged: (value) {
        field.didChange(value);
        onChanged?.call(value ?? false);
      },
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      isError: field.hasError,
      title: title,
      subtitle: field.hasError
          ? Text(requiredText, style: TextStyle(color: theme.colorScheme.error))
          : null,
    );
  }
}
