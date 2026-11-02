import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';

// No links yet: legal-paginas will add the texts and their real versions.
class AcceptanceCheckbox extends FormField<bool> {
  AcceptanceCheckbox({super.key})
    : super(
        initialValue: false,
        validator: (accepted) => accepted == true ? null : '',
        builder: (field) => _AcceptanceTile(field: field),
      );
}

class _AcceptanceTile extends StatelessWidget {
  const _AcceptanceTile({required this.field});

  final FormFieldState<bool> field;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return CheckboxListTile(
      value: field.value,
      onChanged: field.didChange,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      isError: field.hasError,
      title: Text(l10n.registerAccept),
      subtitle: field.hasError
          ? Text(
              l10n.registerAcceptRequired,
              style: TextStyle(color: theme.colorScheme.error),
            )
          : null,
    );
  }
}
