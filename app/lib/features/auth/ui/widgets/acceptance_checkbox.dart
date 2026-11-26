import 'package:brackety_core/brackety_core.dart';
import 'package:flutter/material.dart';

/// A required checkbox: the form does not validate until it is ticked.
class AcceptanceCheckbox extends FormField<bool> {
  AcceptanceCheckbox({
    super.key,
    required Widget title,
    required String requiredText,
    bool initialValue = false,
    bool boxed = false,
    ValueChanged<bool>? onChanged,
  }) : super(
         initialValue: initialValue,
         validator: (accepted) => accepted == true ? null : '',
         builder: (field) => _AcceptanceTile(
           field: field,
           title: title,
           requiredText: requiredText,
           boxed: boxed,
           onChanged: onChanged,
         ),
       );
}

class _AcceptanceTile extends StatelessWidget {
  const _AcceptanceTile({
    required this.field,
    required this.title,
    required this.requiredText,
    required this.boxed,
    this.onChanged,
  });

  final FormFieldState<bool> field;
  final Widget title;
  final String requiredText;

  /// In a white box, outlined in the error colour while it is missing: the last step of a long form.
  final bool boxed;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tile = CheckboxListTile(
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
    if (!boxed) return tile;
    final scheme = theme.colorScheme;
    // A Material, not a DecoratedBox: the tile paints its splash on the nearest Material.
    return Material(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: field.hasError ? scheme.error : scheme.outlineVariant,
          width: field.hasError ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.s),
        child: tile,
      ),
    );
  }
}
